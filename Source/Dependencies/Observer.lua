local Observer = {}

Observer.Type = "Observer"

Observer.Internal = {}
Observer.Prototype = {
	Internal = Observer.Internal,
}
Observer.Interface = {
	Internal = Observer.Internal,
}

function Observer.Prototype:IsObserverEvent(event)
	return self.Event == event
end

function Observer.Prototype:InvokeObserver(...)
	return self.Callback(...)
end

function Observer.Prototype:ToString()
	return `{Observer.Type}<"{self.Event}">`
end

function Observer.Interface.new(targetEvent, targetCallback)
	return setmetatable({
		Event = targetEvent,
		Callback = targetCallback,
	}, {
		__index = Observer.Prototype,
		__type = Observer.Type,
		__tostring = function(self)
			return self:ToString()
		end,
	})
end

return Observer.Interface
