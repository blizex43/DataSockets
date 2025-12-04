-- Compiled with roblox-ts v3.0.0
local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("TypeScript"):WaitForChild("RuntimeLib"))
local _DataFormat = TS.import(script, game:GetService("ServerStorage"), "Modules", "Networking", "Data", "DataSockets", "DataControls", "DataFormat")
local formatStructure = _DataFormat.formatStructure
local formatStructureToObject = _DataFormat.formatStructureToObject
local function resolveStructure(structure, ...)
	local otherStructure = { ... }
	local formattedStructure = formatStructure(formatStructureToObject(structure))
	for i = 1, #otherStructure - 1 do
		for name, value in pairs(otherStructure[i + 1]) do
			formattedStructure[name] = value
		end
	end
	return formattedStructure
end
return {
	resolveStructure = resolveStructure,
}
