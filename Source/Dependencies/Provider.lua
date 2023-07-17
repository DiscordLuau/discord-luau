local Provider = {}

Provider.Type = "Provider"

Provider.Internal = {}
Provider.Prototype = {
	Internal = Provider.Internal,
}
Provider.Interface = {
	Internal = Provider.Internal,
}

function Provider.Prototype:Subscribe(observer)
	table.insert(self._Observers, observer)
end

function Provider.Prototype:Unsubscribe(observer)
	local index = table.find(self._Observers, observer)

	if index then
		table.remove(self._Observers, index)
	end
end

function Provider.Prototype:UnsubscribeAll()
	self._Observers = {}
end

function Provider.Prototype:InvokeObservers(observerEvent, ...)
	for _, observer in self._Observers do
		if not observer:IsObserverEvent(observerEvent) then
			continue
		end

		observer:InvokeObserver(...)
	end
end

function Provider.Prototype:ToString()
	return `{Provider.Type}<"{#self._Observers} Observers">`
end

function Provider.Interface.new()
	return setmetatable({
		_Observers = {},
	}, {
		__index = Provider.Prototype,
		__type = Provider.Type,
		__tostring = function(self)
			return self:ToString()
		end,
	})
end

return Provider.Interface
