-- Compiled with roblox-ts v3.0.0
-- Typescript Literals
local asyncConsole
do
	asyncConsole = setmetatable({}, {
		__tostring = function()
			return "asyncConsole"
		end,
	})
	asyncConsole.__index = asyncConsole
	function asyncConsole.new(...)
		local self = setmetatable({}, asyncConsole)
		return self:constructor(...) or self
	end
	function asyncConsole:constructor()
	end
	function asyncConsole:log(...)
		local msg = { ... }
		return print(unpack(msg))
	end
end
local console = asyncConsole.new()
return {
	asyncConsole = asyncConsole,
	console = console,
}
