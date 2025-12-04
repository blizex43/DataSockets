local Signal = {}
Signal.__index = Signal

function Signal.new()
	local signal ; signal = setmetatable({
		_Bindable = Instance.new("BindableFunction"), 
		_Invoked = Instance.new("BindableEvent"),
		_CallBacks = {},
		CachedReturnValues = {},
		Signal = true, 
		Fired = false

	}, Signal)

	function signal._Bindable.OnInvoke(...)
		local capturedReturnValue 

		for _, callBack in ipairs(signal._CallBacks) do
			local returnVal = callBack(...)

			if capturedReturnValue == nil then
				capturedReturnValue = returnVal
				table.insert(signal.CachedReturnValues, capturedReturnValue)
			end
		end

		signal.Fired = false
		return capturedReturnValue
	end

	return signal
end

function Signal:Fire(...)
	self.Fired = true
	self._Invoked:Fire()

	return #self._CallBacks > 0 and self._Bindable:Invoke(...) or nil
end

function Signal:Connect(callBack)
	assert(typeof(callBack) == "function", "Callback must be a function")

	table.insert(self._CallBacks, callBack)

	return {
		Disconnect = self.Disconnect
	}
end

function Signal:Disconnect()
	self._CallBacks = {}
	self._Bindable.OnInvoke = nil
end

function Signal:Wait()	
	local timeBeforeYield = os.clock()
	self._Invoked.Event:Wait()

	return self.CachedReturnValues[1], os.clock() - timeBeforeYield
end

return Signal