local Utility = {}

local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local ancestor = script:FindFirstAncestor("QuickNetwork")

local Settings = require(ancestor.Settings)
local Constants = require(ancestor.Constants)
local Queue = require(ancestor.AbstractionLayers.Queue)
local Signal = require(ancestor.Classes.Signal)
local QuickNetwork 

local function Session_Locked(data)
	return data.MetaData.SessionJobTime and os.time() - data.MetaData.SessionJobTime < Settings.AssumeDeadSessionLock
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

function Utility.GameBindToClose()
	local sessionLockedData = QuickNetwork.SessionLockedData

	-- No session locked datas?
	if #sessionLockedData == 0 then
		return
	end

	-- Cannot save data on shutdown while on Studio?
	if RunService:IsStudio() and not Settings.SaveDataOnShutDownInStudio then
		Utility.Output(("[QuickNetwork]: Data won't save on server shutdown in Studio as SaveDataOnShutDownInStudio is false"))
		return
	end

	local clearJobsFinished = Signal.new()
	local clearJobs = #sessionLockedData

	for _, data in ipairs(sessionLockedData) do	
		coroutine.wrap(function()  
			if data.MetaData.BoundToClear then
				-- Data is being cleared, wait until it has to prevent bugs:
				data._ListenToClear:Wait()
			else
				data:Clear()
			end

			clearJobs -= 1

			if clearJobs == 0 and not clearJobsFinished.Fired then
				clearJobsFinished:Fire()
			end
		end)()
	end

	-- Yield the thread until clear jobs have finished:
	clearJobsFinished:Wait()
end

function Utility.Is_Default_Data(data, defaultDataTemplate)
	if typeof(defaultDataTemplate) ~= "table" or typeof(data) ~= "table" then
		return false
	end

	for key, value in pairs(data) do
		-- Skip the current iteration if invalid keys are found to prevent inaccurate reading:
		if key == "MetaData" or typeof(value) == "table" and value.Signal then
			continue
		end

		if typeof(value) == "table" then
			if not Utility.Is_Default_Data(value, defaultDataTemplate[key]) then
				return false
			end
		else
			if value ~= defaultDataTemplate[key] then
				return false
			end
		end
	end

	return true
end

function Utility.ResetData(data, defaultDataTemplate)
	for key, value in pairs(defaultDataTemplate) do
		data[key] = value
	end
end

function Utility.Output(message)
	if not Settings.Logging then
		return
	end

	warn(message)
end

function Utility.DeepCopyTable(tabl)
	local deepCopiedTable = {}

	-- Keep the metatable if found:
	setmetatable(deepCopiedTable, getmetatable(tabl))

	for key, value in pairs(tabl) do
		if typeof(value) == "table" then
			deepCopiedTable[key] = Utility.DeepCopyTable(value)
		else
			deepCopiedTable[key] = value
		end
	end

	return deepCopiedTable
end

function Utility.Init(quickNetwork)
	QuickNetwork = quickNetwork
end

function Utility.CheckTableSize(tabl)
	local tablCharacters = #HttpService:JSONEncode(tabl)
	return tablCharacters < Constants.MAX_DATA_CHARACTERS, tablCharacters
end

function Utility.HandleDataSessionLock(dataNetwork, key, backup)
	while true do
		local data, sessionLocked = Queue.QueueAPICall({dataNetwork, key, _, backup}, Utility.LoadData)  

		if not sessionLocked and typeof(data) ~= "table" then
			-- Data couldn’t be loaded 
			break

		elseif not sessionLocked then
			data.MetaData.SessionLockFree = true
			return data
		end
	end
end

function Utility.HeartBeatWait(yield)
	if yield == 0 or typeof(yield) ~= "number" then
		return RunService.Heartbeat:Wait()
	end

	local deltaTimePassed = 0 

	while true do
		if deltaTimePassed >= yield then
			return deltaTimePassed
		end 

		deltaTimePassed += RunService.Heartbeat:Wait()
	end	
end

function Utility.WipeData(dataNetwork, data, wipeBackup)
	local dataStore 
	local pcallTries = 0

	if wipeBackup then
		dataStore = dataNetwork.BackupDataStore
	else
		dataStore = dataNetwork.DataStore
	end

	while pcallTries < Constants.MAX_PCALL_TRIES do
		local success, response = pcall(dataStore.RemoveAsync, dataStore, data.MetaData.Key)

		if success then
			return "WIPED"
		else
			pcallTries += 1

			-- Max pcall tries reached?
			if pcallTries == Constants.MAX_PCALL_TRIES then
				return response
			end

			Utility.HeartBeatWait(Constants.WRITE_COOLDOWN_INTERVAL)
		end
	end
end	

function Utility.SaveData(dataNetwork, data, saveBackup)
	local dataStore 
	local pcallTries = 0

	-- Should data be saved to a backup data store?
	if saveBackup then
		dataStore = dataNetwork.BackupDataStore
	else
		dataStore = dataNetwork.DataStore
	end

	while pcallTries < Constants.MAX_PCALL_TRIES do
		local success, response = pcall(dataStore.UpdateAsync, dataStore, data.MetaData.Key, function()
			local copiedData = Utility.DeepCopyTable(data)

			-- Remove any unsaveable keys to prevent errors:
			SerializeData(copiedData)

			-- Get rid of the meta data if data is about to be cleared:
			if copiedData.MetaData.BoundToClear then
				-- Remove all unnecessary keys in meta data:
				for key, value in pairs(copiedData.MetaData) do
					-- Skip the current iteration if invalid keys are found to prevent bugs:
					if key == "CombinedDataStores" or key == "CombinedKeys" or key == "ReleaseTagJobId" then
						continue
					end

					copiedData.MetaData[key] = nil
				end
			else
				-- Remove all unnecessary keys in meta data:
				for key, value in pairs(copiedData.MetaData) do
					-- Skip the current iteration if invalid keys are found to prevent bugs:
					if key == "SessionJobTime" or key == "SessionLockFree" or key == "CombinedDataStores" or key == "CombinedKeys"  then
						continue
					end

					copiedData.MetaData[key] = nil     
				end
			end

			return copiedData
		end)

		if success then
			return "SAVED"
		else
			--[[ Don't add tries if data is being cleared because we want to keep on retrying
				 unless the pcall was successfull to improve stability:
			]]

			if not data.MetaData.BoundToClear then
				pcallTries += 1
			end

			-- Max pcall tries reached?
			if pcallTries == Constants.MAX_PCALL_TRIES then
				return response
			end

			Utility.HeartBeatWait(Constants.WRITE_COOLDOWN_INTERVAL)
		end
	end
end

function Utility.LoadData(dataNetwork, key, loadMethod, loadBackup, readOnly)	 
	local dataStore
	local pcallTries = 0
	local readOnlyResponse
	local dataSessionLocked

	if loadBackup then
		dataStore = dataNetwork.BackupDataStore 
	else
		dataStore = dataNetwork.DataStore
	end

	while pcallTries < Constants.MAX_PCALL_TRIES do
		local success, response = pcall(dataStore.UpdateAsync, dataStore, key, function(data)
			-- Don't save data unnecessarily if it is only being loaded for read only purposes:
			if readOnly then
				readOnlyResponse = data
				return
			else
				-- No previous data was saved to this key?
				if data == nil then
					return
				end
			end 

			if data.MetaData == nil then
				data.MetaData = {}
			end

			dataSessionLocked = Session_Locked(data)

			if dataSessionLocked then 
				-- Force release the data from another server:
				data.MetaData.ReleaseTagJobId = game.JobId
				
				if loadMethod == "steal" then
					data.MetaData = {             
						SessionLockFree = false,
						SessionJobTime = data.MetaData.SessionJobTime,
						CombinedDataStores = data.MetaData.CombinedDataStores or {},
						CombinedKeys = data.MetaData.CombinedKeys or {},
						ReleaseTagJobId = data.MetaData.ReleaseTagJobId
					}

				elseif loadMethod == "cancel" then
					readOnlyResponse = data
					return
				end
			else  
				-- No session lock, keep one:
				data.MetaData = {
					SessionJobTime = os.time(),
					SessionLockFree = true,
					CombinedDataStores = data.MetaData.CombinedDataStores or {},
					CombinedKeys = data.MetaData.CombinedKeys or {}
				}
			end	

			return data
		end)

		if success then		
			return readOnlyResponse or response, dataSessionLocked
		else
			pcallTries += 1

			--[[ If response contains 504 or 501, then we know that the
				 data was corrupted:
			]]

			if response:find("504") or response:find("501") then
				return "CORRUPTED"

				-- Max pcall tries reached?
			elseif pcallTries == Constants.MAX_PCALL_TRIES then
				return response
			end

			Utility.HeartBeatWait(Constants.WRITE_COOLDOWN_INTERVAL)
		end
	end
end

Queue.Init(Utility)

return Utility