-- Compiled with roblox-ts v3.0.0
local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("TypeScript"):WaitForChild("RuntimeLib"))
local TagAliases = TS.import(script, game:GetService("ServerStorage"), "Modules", "Networking", "Data", "DataSockets", "Utils", "TagAliases")
local RuleCodes = TS.import(script, game:GetService("ServerStorage"), "Modules", "Networking", "Data", "DataSockets", "DataControls", "DataRules", "RuleCodes")
local function isRuleBroken(player, playerData)
	-- Ask
	if player.AccountAge < 7 then
		return 2
	elseif playerData == nil then
		return 1
	elseif game.Workspace:HasTag(TagAliases.ServerShutdown) then
		return 3
	end
end
local function ruleBreak(player, ruleCode)
	local _serverOutput = RuleCodes[ruleCode].ServerOutput
	local _name = player.Name
	local _exp = string.format(_serverOutput, _name)
	local _playerOutput = RuleCodes[ruleCode].PlayerOutput
	local _name_1 = player.Name
	return { _exp, string.format(_playerOutput, _name_1) }
end
return {
	isRuleBroken = isRuleBroken,
	ruleBreak = ruleBreak,
}
