import { ServerStorage } from "@rbxts/services";
const assets = ServerStorage.FindFirstChild("Assets") as Folder;
const templatePlayerDataFolder = assets.FindFirstChild("PlayerData") as Folder;
const template = templatePlayerDataFolder.FindFirstChild("Template") as Folder;
export const livePlayerData = ServerStorage.FindFirstChild("LivePlayerData") as Folder;

export const DataOptions = {
	Prefix: "playerOfIndex[",
	Suffix: "]",
	Name: "NewStoreReborn22",
	Structure: template.GetChildren(),
	StructureExtern: {},
};

export const excludedIndexes = {
	MetaData: "MetaData",
	ListenToUpdate: "ListenToUpdate",
	ListenToSave: "ListenToSave",
	ListenToWipe: "ListenToWipe",
	_ListenToClear: "ListenToClear",
	Set: "Set",
	SetTable: "SetTable",
	IsActive: "IsActive",
	IsBackup: "IsBackup",
	Save: "Save",
	ClearBackup: "ClearBackup",
	Clear: "Clear",
	Reconcile: "Reconcile",
	Wipe: "Wipe",
	CombineKeysAsync: "CombineKeysAsync",
	CombineDataStoresAsync: "CombineDataStoresAsync",
};
