-- Compiled with roblox-ts v3.0.0
--[[
	*
	 * setTimeout in TypeScript functions identically to its JavaScript counterpart,
	 * scheduling a function to execute after a specified delay in milliseconds.
	 * TypeScript, being a superset of JavaScript, automatically transcompiles
	 * setTimeout calls into JavaScript for execution.
	 * @param func - Input the function for it too call after waiting the set time.
	 * @param waitTime - Input the amount of time in milliseconds to wait for the thread to execute.
	 * @returns a thread that will run after the set amount of time.
	 *
]]
local function setTimeout(func, waitTime)
	if waitTime == nil then
		waitTime = 0
	end
	return task.delay(waitTime / 1000, func)
end
--[[
	*
	 * clearTimeout prevents the scheduled function from executing if it hasn't already
	 * @param thread - Input the thread that you've started for it to cancel
	 *
]]
local function clearTimeout(thread)
	return coroutine.close(thread)
end
local Error
do
	Error = setmetatable({}, {
		__tostring = function()
			return "Error"
		end,
	})
	Error.__index = Error
	function Error.new(...)
		local self = setmetatable({}, Error)
		return self:constructor(...) or self
	end
	function Error:constructor(msg)
		return error(`{msg}\n{debug.traceback()}`)
	end
end
local Warn
do
	Warn = setmetatable({}, {
		__tostring = function()
			return "Warn"
		end,
	})
	Warn.__index = Warn
	function Warn.new(...)
		local self = setmetatable({}, Warn)
		return self:constructor(...) or self
	end
	function Warn:constructor(msg)
		warn(`{msg}\n{debug.traceback()}`)
	end
end
return {
	setTimeout = setTimeout,
	clearTimeout = clearTimeout,
	Error = Error,
	Warn = Warn,
}
