-- Compiled with roblox-ts v3.0.0
local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("TypeScript"):WaitForChild("RuntimeLib"))
-- Sample Usage
local DataSockets = TS.import(script, game:GetService("ServerStorage"), "Modules", "Networking", "Data", "DataSockets")
local console = TS.import(script, game:GetService("ServerStorage"), "Modules", "Networking", "Data", "DataSockets", "Utils", "Natives", "Console").console
local TagAliases = TS.import(script, game:GetService("ServerStorage"), "Modules", "Networking", "Data", "DataSockets", "Utils", "TagAliases")
-- Listeners
DataSockets.onPlayerDataConstructed:Connect(function(...)
	local args = { ... }
	local _binding = args
	local player = _binding[1]
	local playerData = _binding[2]
	player:AddTag(TagAliases.DataLoaded)
	console:log(`{player.Name} has successfully loaded into the game!`)
	local loginAmount = playerData.loginAmount
	playerData:Set("loginAmount", loginAmount + 1)
end)
DataSockets.onDataChanged:Connect(function(...)
	local args = { ... }
	local _binding = args
	local player = _binding[1]
	local key = _binding[2]
	local value = _binding[3]
	console:log(`Data of player [{player.Name}] has changed!\
		\n[key] => {key}\
		\n[value] => {value}]`)
end)
DataSockets:listenForPlayers()
print(DataSockets)
