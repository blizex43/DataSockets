-- Compiled with roblox-ts v3.0.0
local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("TypeScript"):WaitForChild("RuntimeLib"))
local ServerStorage = TS.import(script, game:GetService("ReplicatedStorage"), "TypeScript", "node_modules", "@rbxts", "services").ServerStorage
local assets = ServerStorage:FindFirstChild("Assets")
local templatePlayerDataFolder = assets:FindFirstChild("PlayerData")
local template = templatePlayerDataFolder:FindFirstChild("Template")
local livePlayerData = ServerStorage:FindFirstChild("LivePlayerData")
local DataOptions = {
	Prefix = "playerOfIndex[",
	Suffix = "]",
	Name = "NewStoreReborn22",
	Structure = template:GetChildren(),
	StructureExtern = {},
}
local excludedIndexes = {
	MetaData = "MetaData",
	ListenToUpdate = "ListenToUpdate",
	ListenToSave = "ListenToSave",
	ListenToWipe = "ListenToWipe",
	_ListenToClear = "ListenToClear",
	Set = "Set",
	SetTable = "SetTable",
	IsActive = "IsActive",
	IsBackup = "IsBackup",
	Save = "Save",
	ClearBackup = "ClearBackup",
	Clear = "Clear",
	Reconcile = "Reconcile",
	Wipe = "Wipe",
	CombineKeysAsync = "CombineKeysAsync",
	CombineDataStoresAsync = "CombineDataStoresAsync",
}
return {
	livePlayerData = livePlayerData,
	DataOptions = DataOptions,
	excludedIndexes = excludedIndexes,
}
