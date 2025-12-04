local QuickNetwork = {BindToShutdown = false, SessionLockedData = {}}

local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local Settings = require(script.Settings)
local Data = require(script.Classes.Data)
local Utility = require(script.AbstractionLayers.Utility)
local Signal = require(script.Classes.Signal)
local Queue = require(script.AbstractionLayers.Queue)
local Constants = require(script.Constants)
local MockDataStoreService = require(script.Classes.MockDataStoreService)

local dataStoreErrorHandleFinish = Signal.new()
local globalMock = false

local DataNetwork = {CachedDataNetworks = {}, DataNetworkCreationQueue = {}}
DataNetwork.__index = DataNetwork

function DataNetwork:LoadDataAsync(key, loadMethod, readOnly) 
	assert(typeof(key) == "string" or typeof(key) == "number", Constants.INVALID_ARGUMENT_TYPE:format(1, "number or string", typeof(key)))
	assert(#tostring(key) < Constants.MAX_KEY_CHARACTERS, Constants.INVALID_ARGUMENT_TYPE:format(1, ("key characters <= %s"):format(Constants.MAX_KEY_CHARACTERS), ("%s characters"):format(#tostring(key))))
	assert(typeof(loadMethod) == "string" or loadMethod == nil, Constants.INVALID_ARGUMENT_TYPE:format(2, "load method [Cancel, Steal, nil]", tostring(loadMethod)))
	assert(typeof(readOnly) == "boolean" or readOnly == nil, Constants.INVALID_ARGUMENT_TYPE:format(3, "boolean or nil", typeof(readOnly)))

	if loadMethod then
		loadMethod = loadMethod:lower()
	end

	-- Wait for the data to successfully load instead of loading it again to prevent bugs:
	if self._DataLoadingQueue[key] then
		self._DataLoadingQueue[key]:Wait()
	end

	-- Return cached data if found instead of loading a new one:
	if self._CachedData[key] then 
		return self._CachedData[key]
	end

	self._DataLoadingQueue[key] = Signal.new()

	local data, sessionLocked = Queue.QueueAPICall({self, key, loadMethod, false, readOnly}, Utility.LoadData)  
	local backup = false
	local loaded = false

	if typeof(data) ~= "table" then
		if data == nil then
			-- Case #1: Data is nil

			-- Make sure data isn't nil incase of a load method:
			if sessionLocked and loadMethod == "cancel" then
				return
			end 

			data = Utility.HandleDataSessionLock(self, key, false)
		else   
			-- Data wasn’t saved, load backup data:
			local backupData, sessionLocked = Queue.QueueAPICall({self, key, loadMethod, true, readOnly}, Utility.LoadData) 

			if sessionLocked then
				backupData = Utility.HandleDataSessionLock(self, key, true)
			end

			if typeof(backupData) == "table" then
				data = backupData
				loaded = true
			else
				loaded = false
			end
		end
	end

	if data == "CORRUPTED" then
		-- Case #2: Data was loaded but is corrupted
		Utility.Output(("[QuickNetwork]: [KEY: %s]: Data loaded was corrupted"):format(key))	
		local response = self.DataCorruptionLoadSignal:Fire(key, "Data loaded was corrupted")

		response = typeof(response) == "string" and response:lower() or response
		assert(Constants.DATA_CORRUPTIONLOADSIGNAL_RETURN_VALUES[response] or Constants.DATA_CORRUPTIONLOADSIGNAL_RETURN_VALUES[typeof(response)], Constants.INVALID_ARGUMENT_TYPE:format(1, "data corruption return value [Cancel, LoadBackup, nil, Table]", tostring(response)))

		if response == "loadbackup" then
			local backupData, sessionLocked = Queue.QueueAPICall({self, key, loadMethod, true, readOnly}, Utility.LoadData) 

			if sessionLocked then
				backupData = Utility.HandleDataSessionLock(self, key, true)
			end

			if typeof(backupData) == "table" then
				data = backupData
			end

		elseif response == "cancel" then
			return	

		elseif typeof(response) == "table" then
			local tableSizeUnderLimit, characters = Utility.CheckTableSize(response)
			assert(tableSizeUnderLimit, Constants.INVALID_ARGUMENT_TYPE:format(1, ("expected data characters lower than %s"):format(Constants.MAX_DATA_CHARACTERS), characters))

			data = response
		end

		loaded = true

	elseif typeof(data) == "string" then
		-- Case #3: Data couldn't be loaded
		Utility.Output(("[QuickNetwork]: [KEY: %s]: Data couldn't be loaded, error message: %s"):format(key, data))	
		local response = self.DataErrorLoadSignal:Fire(key, ("Error loading data, %s"):format(data))
		assert(Constants.DATA_ERRORLOADSIGNAL_RETURN_VALUES[response] or Constants.DATA_ERRORLOADSIGNAL_RETURN_VALUES[typeof(response)], Constants.INVALID_ARGUMENT_TYPE:format(1, "data error return value [Cancel, LoadBackup, nil, Table]", tostring(response)))

		if response == "loadbackup" then
			local backupData, sessionLocked = Queue.QueueAPICall({self, key, loadMethod, true, readOnly}, Utility.LoadData) 
			if sessionLocked then
				backupData = Utility.HandleDataSessionLock(self, key, true)
			end

			data = typeof(backupData) == "table" and backupData or nil

		elseif response == "cancel" then
			return

		elseif typeof(response) == "table" then
			local tableSizeUnderLimit, characters = Utility.CheckTableSize(response)
			assert(tableSizeUnderLimit, Constants.INVALID_ARGUMENT_TYPE:format(1, ("expected data characters lower than %s"):format(Constants.MAX_DATA_CHARACTERS), characters))

			data = response
		end

		loaded = typeof(data) == "table" 
		backup = loaded

		if typeof(data) == "table" then
			loaded = true
		end
	else
		loaded = true
	end

	-- Use default data if data isn't a table 
	if typeof(data) ~= "table" then
		data = Utility.DeepCopyTable(self.DefaultDataTemplate)
	end

	-- No meta data found?
	if data.MetaData == nil then
		data.MetaData = {
			CombinedDataStores = {},
			CombinedKeys = {},
			SessionJobTime = os.time(),
			SessionLockFree = true,
		}
	end

	data.MetaData.Key = key 
	data.MetaData.BoundToClear = false
	data.MetaData.Backup = backup
	data.MetaData.Updated = false	
	data.MetaData.Cleared = false
	data.MetaData.Loaded = loaded
	data.MetaData.DataNetwork = Utility.DeepCopyTable(self)

	-- Make sure data isn't loaded in read only mode to prevent unnecessary signal creation:
	if not readOnly then
		data.ListenToUpdate = Signal.new()
		data.ListenToSave = Signal.new()
		data.ListenToWipe = Signal.new()
		data._ListenToClear = Signal.new() 
	end

	setmetatable(data, {__index = function(_, key)
		local value = rawget(Data, key)
		assert(not (typeof(value) == "function" and readOnly), "Writing or calling any methods on data isn't possible as it is read only!")

		return value
	end})

	self._CachedData[key] = data
	self._DataLoadingQueue[key]:Fire()
	self._DataLoadingQueue[key] = nil

	-- Auto saving data:
	if data.MetaData.Loaded and Settings.AutoSaveData then
		coroutine.wrap(function()
			while not data.MetaData.Cleared do
				local latestData = Queue.QueueAPICall({self, key, _, backup, true}, Utility.LoadData)

				-- Another server requested this server to release the data forcefully?
				if latestData.MetaData.ReleaseTagJobId ~= nil and latestData.MetaData.ReleaseTagJobId ~= game.JobId then
					--[[
						Break out of this while loop after clearing the data in case of a EXTREMELY
						rare case where data still isn't successfully cleared:
					]]

					data:Clear()
					break
				end

				-- Make sure data is updated to prevent unnecessarily saving the data:
				if data.MetaData.Updated and data.MetaData.SessionLockFree then
					data.MetaData.AutoSaving = true
					data:Save() 
				end

				Utility.HeartBeatWait(Settings.AutoSaveInterval)
			end
		end)()
	end

	if not readOnly then
		local index = #QuickNetwork.SessionLockedData + 1
		table.insert(QuickNetwork.SessionLockedData, index, data)

		data._ListenToClear:Connect(function()
			QuickNetwork.SessionLockedData[index] = nil
			self._CachedData[key] = nil

			-- Disconnect all signals:
			for _, signal in pairs(data) do
				-- Skip the current iteration if current value is not a signal:
				if typeof(signal) ~= "table" or not signal.Signal then
					continue
				end

				signal:Disconnect()	
			end
		end)
	end
	return data
end

function DataNetwork:GetCachedData(key)
	-- Is data loading, if so, wait for the data to load:
	local dataLoading = self._DataLoadingQueue[key]
	if dataLoading then
		dataLoading:Wait()
	end

	local cachedData = self._CachedData[key]

	-- Cached data not found?
	if not cachedData then
		warn(("%s's cached data was not found"):format(key))
		return
	end

	return cachedData
end

function QuickNetwork.GetDataNetwork(name, defaultDataTemplate, mock) 
	--[[ Wait for the data network to be created and cached and use that one instead of 
		 creating a new one:
	]]
	if DataNetwork.DataNetworkCreationQueue[name] then
		DataNetwork.DataNetworkCreationQueue[name]:Wait()
	end

	-- Return cached data network if found:
	if DataNetwork.CachedDataNetworks[name] then
		return DataNetwork.CachedDataNetworks[name]
	end

	assert(typeof(name) == "string", Constants.INVALID_ARGUMENT_TYPE:format(1, "string", typeof(name)))
	assert(typeof(defaultDataTemplate) == "table", Constants.INVALID_ARGUMENT_TYPE:format(2, "table", typeof(defaultDataTemplate)))
	assert(typeof(mock) == "boolean" or mock == nil, Constants.INVALID_ARGUMENT_TYPE:format(3, "boolean or nil", typeof(mock)))

	local _, characters = Utility.CheckTableSize(defaultDataTemplate)
	assert(characters <= Constants.MAX_DATA_CHARACTERS, Constants.INVALID_ARGUMENT_TYPE:format(2, ("data characters <= %s"):format(Constants.MAX_KEY_CHARACTERS), characters))

	if not dataStoreErrorHandleFinish.Fired then
		dataStoreErrorHandleFinish:Wait()
		dataStoreErrorHandleFinish:Disconnect()
	end

	DataNetwork.DataNetworkCreationQueue[name] = Signal.new()
	local dataNetworkCreationSignal = DataNetwork.DataNetworkCreationQueue[name]

	local dataNetwork = {
		DefaultDataTemplate = defaultDataTemplate,
		_CachedData = {},
		_DataLoadingQueue = {},

		-- Signals
		DataCorruptionLoadSignal = Signal.new(),
		DataErrorLoadSignal = Signal.new(),
	}

	if globalMock or mock then
		dataNetwork.DataStore = MockDataStoreService:GetDataStore(name)
		dataNetwork.BackupDataStore = MockDataStoreService:GetDataStore(Constants.BACKUP_DATASTORE_NAME:format(name)) 
	else
		dataNetwork.DataStore = DataStoreService:GetDataStore(name)
		dataNetwork.BackupDataStore = DataStoreService:GetDataStore(Constants.BACKUP_DATASTORE_NAME:format(name)) 
	end

	DataNetwork.CachedDataNetworks[name] = dataNetwork 
	dataNetworkCreationSignal:Fire()
	dataNetworkCreationSignal:Disconnect()
	DataNetwork.DataNetworkCreationQueue[name] = nil

	return setmetatable(dataNetwork, DataNetwork)
end

Data.Init(QuickNetwork)
Utility.Init(QuickNetwork)
game:BindToClose(Utility.GameBindToClose)

-- Handle any data store related errors in a new scope:
do
	local TestDataStore = DataStoreService:GetDataStore("_TestDataStore")

	assert(not RunService:IsClient(), "[QuickNetwork]: Is running on the client, won't function!")

	coroutine.wrap(function()
		local response = select(2, pcall(TestDataStore.GetAsync, TestDataStore, "_"))

		if response then
			if response:find("403") then
				-- API Services are disabled
				globalMock = Settings.UseMockDataStoreOffline
				warn(("[QuickNetwork]: API services are disabled, %s"):format(globalMock and "will use MockDataStoreService" or "won't function!"))

			elseif response:find("502") then
				-- No internet access
				globalMock = Settings.UseMockDataStoreOffline
				warn(("[QuickNetwork]: No internet access or error processing on Roblox servers, %s"):format(globalMock and "will use MockDataStoreService" or "won't function!"))	

			elseif response:find("402") then
				globalMock = Settings.UseMockDataStoreOffline
				-- Rare case: server is shutting down as soon as this module was required
				warn(("[QuickNetwork]: Server is shutting down, won't function!"))
			end
		end

		dataStoreErrorHandleFinish:Fire()
	end)()
end

return QuickNetwork 
