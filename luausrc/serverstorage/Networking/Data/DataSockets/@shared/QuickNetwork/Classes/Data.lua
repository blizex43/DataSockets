local Data = {}
Data.__index = Data 

local RunService = game:GetService("RunService")

local ancestor = script:FindFirstAncestor("QuickNetwork")

local Settings = require(ancestor.Settings)
local Utility = require(ancestor.AbstractionLayers.Utility)
local Queue = require(ancestor.AbstractionLayers.Queue)
local Signal = require(script.Parent.Signal)
local Constants = require(ancestor.Constants)

local QuickNetwork 

local function ReconcileTable(tabl, reconcileTable)
	for key, value in pairs(reconcileTable) do
		if tabl[key] == nil then
			tabl[key] = typeof(value) == "table" and Utility.DeepCopyTable(value) or value 

		elseif typeof(reconcileTable[key]) == "table" then
			ReconcileTable(tabl[key], Utility.DeepCopyTable(reconcileTable[key]))
		end
	end
end

local function SerializeData(data)
	for key, value in pairs(data) do
		if typeof(value) == "table" and value.Signal then
			data[key] = nil

		elseif typeof(value) == "table" then
			SerializeData(value)

		elseif typeof(value) == "Instance" then
			data[key] = nil
		end
	end
end

function Data.Init(module)
	QuickNetwork = module
end

function Data:CombineKeysAsync(...)
	local keys = {...}

	assert(next(keys), "Keys must not be empty")

	-- Check combined keys:
	for index, key in ipairs(keys) do
		--[[ Make sure key doesn't exist, if it does, then the data
			 was previously combined with that same key so therefore we need to
			 remove that key to prevent unnecessarily combining the data again:
		]]

		-- Key already combined?
		if self.MetaData.CombinedKeys[key] then
			Utility.Output(("[QuickNetwork]: [KEY: %s] was already combined"):format(key))
			-- Remove the key:
			table.remove(keys, index)
		end

		self.MetaData.CombinedKeys[key] = true	
	end

	local dataNetwork = self.MetaData.DataNetwork	

	dataNetwork.DataCorruptionLoadSignal:Connect(function()
		return "LoadBackup"
	end)

	dataNetwork.DataErrorLoadSignal:Connect(function()
		return "LoadBackup"
	end)

	for _, key in ipairs(keys) do
		-- Load data in read only mode to prevent unnnecessary saving:
		local data = dataNetwork:LoadDataAsync(key, "Steal", true)

		-- Skip the current iteration if data is empty:
		if next(data) == nil then 
			continue
		end

		for key, value in pairs(data) do
			-- Skip the current iteration if invalid keys are found to prevent bugs:
			if typeof(value) == "table" and value.Signal or key == "MetaData" then
				continue
			end

			self:Set(key, value)
		end
	end

	-- Disconnect unneeded signals:
	dataNetwork.DataCorruptionLoadSignal:Disconnect()
	dataNetwork.DataErrorLoadSignal:Disconnect()
end

function Data:CombineDataStoresAsync(...)
	local dataStoreNames = {...}

	assert(next(dataStoreNames), "Data store names must not be empty")

	-- Check combined data stores:
	for index, dataStoreName in ipairs(dataStoreNames) do
		--[[ Make sure data store name doesn't exist, if it does, then the data
			 was previously combined with that data store name so therefore we need to
			 remove that key to prevent unnecessarily combining the data again with that data store:
		]]

		-- Data store already combined?
		if self.MetaData.CombinedDataStores[dataStoreName] then
			Utility.Output(("[QuickNetwork]: [DataStore: %s] was already combined"):format(dataStoreName))
			-- Remove the key:
			table.remove(dataStoreName, index)
		end

		self.MetaData.CombinedDataStores[dataStoreName] = true	
	end

	for _, name in ipairs(dataStoreNames) do
		local dataNetwork = QuickNetwork.GetDataNetwork(name, {})

		dataNetwork.DataCorruptionLoadSignal:Connect(function()
			return "LoadBackup"
		end)

		dataNetwork.DataErrorLoadSignal:Connect(function()
			return "LoadBackup"
		end)

		-- Load data in read only mode to prevent unnnecessary saving:
		local data = dataNetwork:LoadDataAsync(self.MetaData.Key, "Steal", true)

		-- Skip the current iteration if data is empty:
		if next(data) == nil then 
			continue
		end

		local newKeyValue = false

		for key, value in pairs(data) do
			-- Skip the current iteration if invalid keys are found to prevent bugs:
			if typeof(value) == "table" and value.Signal or key == "MetaData" then
				continue
			end

			warn(key, value)

			self:Set(key, value)
		end

		-- Disconnect unwanted signals:
		dataNetwork.DataCorruptionLoadSignal:Disconnect()
		dataNetwork.DataErrorLoadSignal:Disconnect()
	end
end

function Data:Set(key, value)
	-- Make sure key isn't the same value to prevent unnecessarily updating the data:
	if self[key] == value then
		return
	end

	self[key] = value
	self.MetaData.Updated = true
	self.ListenToUpdate:Fire(key, value)
end

function Data:SetTable(value, ...)	
	local arguments = {...}
	local data = self 
	local index = arguments[#arguments]

	for i, v in ipairs(arguments) do
		-- Break out of the loop if we're at the last index:

		if i == #arguments then 
			break 
		end

		self = self[v]
	end

	local currentValue = self[index]

	-- Make sure key isn't the same value to prevent unnecessarily updating the data:
	if currentValue == value then
		return
	end

	self[index] = value
	data.ListenToUpdate:Fire(index, value, self)
end

function Data:IsActive()
	return not self.MetaData.Cleared 
end

function Data:IsBackup()
	return self.MetaData.Backup
end

function Data:Save(forceSave) 
	assert(typeof(forceSave) == "boolean" or forceSave == nil, Constants.INVALID_ARGUMENT_TYPE:format(1, "boolean or nil", typeof(forceSave)))
	assert(self:IsActive(), "Saving data isn't possible since it was cleared")

	local key = self.MetaData.Key
	local dataNetwork = self.MetaData.DataNetwork
	local boundToClear = self.MetaData.BoundToClear
	local backup = self:IsBackup()
	local autoSaving = self.MetaData.AutoSaving

	local dataSaveFormat = boundToClear and "clear" or autoSaving and "auto save" or "save"
	local dataTypeFormat = backup and "backup " or ""

	-- Safety checks:
	if (RunService:IsStudio()) and not Settings.SaveDataInStudio then
		Utility.Output(("[QuickNetwork]: [KEY: %s]: Cannot %s %sdata in Studio as SaveInStudio is false"):format(key, dataSaveFormat, dataTypeFormat))
		self.MetaData.BoundToClear = false
		return

	elseif not self.MetaData.Loaded then
		Utility.Output(("[QuickNetwork]: [KEY: %s]: Cannot %s %sdata as it wasn't loaded"):format(key, dataSaveFormat, dataTypeFormat))
		self.MetaData.BoundToClear = false
		return

	elseif (not self.MetaData.Updated) and (not forceSave) and not self.MetaData.BoundToClear then
		Utility.Output(("[QuickNetwork]: [KEY: %s]: Cannot %s %sdata as it wasn't updated"):format(key, dataSaveFormat, dataTypeFormat))
		self.MetaData.BoundToClear = false
		return

	elseif (not self.MetaData.SessionLockFree) and not forceSave then
		Utility.Output(("[QuickNetwork]: [KEY: %s]: Cannot %s %sdata as it was previously session locked"):format(key, dataSaveFormat, dataTypeFormat))
		self.MetaData.BoundToClear = false
		return
	end

	-- Make sure saving backup data is allowed if data is a backup:
	if (not Settings.SaveDataBackups) and backup then
		return
	end

	local response = Queue.QueueAPICall({dataNetwork, self, backup}, Utility.SaveData)

	if response == "SAVED" then
		dataSaveFormat = boundToClear and "Cleared" or autoSaving and "Auto saved" or "Saved"

		if self.MetaData.BoundToClear then
			self._ListenToClear:Fire()
			self.MetaData.Cleared = true
		end

		self.MetaData.Updated = false
		self.ListenToSave:Fire(backup)
		Utility.Output(("[QuickNetwork]: [KEY: %s]: %s %sdata"):format(key, dataSaveFormat, dataTypeFormat))
	else
		dataSaveFormat = boundToClear and "clearing" or autoSaving and "auto saving" or "saving"

		Utility.Output(("[QuickNetwork]: [KEY: %s]: Error %s %sdata, error: %s"):format(key, dataSaveFormat, dataTypeFormat, response))
	end

	-- Save backup data in a new thread if allowed:
	if not backup and Settings.SaveDataBackups then
		-- Save backup data in a new thread to prevent yielding the current thread unnecessarily:
		coroutine.wrap(Queue.QueueAPICall)({dataNetwork, self, backup}, Utility.SaveData)
	end

	-- Setting them here to avoid repetitiveness:
	self.MetaData.AutoSaving = false
	self.MetaData.BoundToClear = false
end

function Data:ClearBackup()
	self.MetaData.Backup = false
end

function Data:Clear()
	assert(self:IsActive(), "Clearing data isn't possible since it was cleared")

	-- Don't clear data if it already is being cleared to prevent bugs:
	if self.MetaData.BoundToClear then
		return
	end

	self.MetaData.BoundToClear = true
	self:Save()
end	

function Data:Reconcile() 
	ReconcileTable(self, self.MetaData.DataNetwork.DefaultDataTemplate)
end

function Data:Wipe(forceWipe)
	assert(typeof(forceWipe) == "boolean" or forceWipe == nil, Constants.INVALID_ARGUMENT_TYPE:format(1, "boolean or nil", typeof(forceWipe)))
	assert(self:IsActive(), "Wiping %s data isn't possible since it was cleared")

	local key = self.MetaData.Key
	local dataNetwork = self.MetaData.DataNetwork
	local backup = self:IsBackup()

	local dataTypeFormat = backup and "backup " or ""

	-- Safety checks:
	if not self.MetaData.Loaded then
		Utility.Output(("[QuickNetwork]: [KEY: %s]: Cannot wipe %sdata as it wasn't loaded"):format(key, dataTypeFormat))
		return		

	elseif (Utility.Is_Default_Data(self, dataNetwork.DefaultDataTemplate)) and not forceWipe then
		Utility.Output(("[QuickNetwork]: [KEY: %s]: Cannot wipe %sdata as it wasn't updated from the default data"):format(key, dataTypeFormat))
		return

	elseif (self.MetaData.BoundToClear) and not forceWipe then
		Utility.Output(("[QuickNetwork]: [KEY: %s]: Can't wipe %sdata as data is being cleared"):format(key, dataTypeFormat))
		return
	end

	local response = Queue.QueueAPICall({dataNetwork, self, backup}, Utility.WipeData)

	if response == "WIPED" then
		self.ListenToWipe:Fire(backup)
		Utility.ResetData(self, Utility.DeepCopyTable(dataNetwork.DefaultDataTemplate))
		Utility.Output(("[QuickNetwork]: [KEY: %s]: Wiped %sdata"):format(key, dataTypeFormat))
	else
		Utility.Output(("[QuickNetwork]: [KEY: %s]: Error wiping %sdata, error: %s"):format(key, dataTypeFormat, response))
	end

	if not backup then
		-- Wipe backup data in a new thread to prevent yielding the current thread unnecessarily:
		coroutine.wrap(Queue.QueueAPICall)({dataNetwork, self, backup}, Utility.WipeData)
	end
end

return Data
