-- Compiled with roblox-ts v3.0.0
local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("TypeScript"):WaitForChild("RuntimeLib"))
local Error = TS.import(script, game:GetService("ServerStorage"), "Modules", "Networking", "Data", "DataSockets", "Utils", "Natives", "Functions").Error
local function Object(obj)
	return {
		keys = function()
			local keys = {}
			for key in pairs(obj) do
				table.insert(keys, key)
			end
			return keys
		end,
		values = function()
			local values = {}
			for _, value in pairs(obj) do
				table.insert(values, value)
			end
			return values
		end,
		entries = function()
			local object = {}
			for key, value in pairs(obj) do
				object[key] = value
			end
			return object
		end,
		hasOwn = function(key)
			if not obj then
				Error.new(`{obj} is not an object.`)
			end
			for k in pairs(obj) do
				if k == key then
					return true
				end
			end
			return false
		end,
	}
end
return {
	Object = Object,
}
