local Event = {}

Event.Type = "Event"

Event.Internal = {}
Event.Prototype = {
	Internal = Event.Internal,
}
Event.Interface = {
	Internal = Event.Internal,
}

function Event.Prototype:Disconnect()
	self.Callback = nil
end

function Event.Prototype:Connect(callback)
	self.Callback = callback
end

function Event.Prototype:Invoke(...)
	if not self.Callback then
		return
	end

	self.Callback(...)
end

function Event.Prototype:ToString()
	return `{Event.Type}<"{tostring(self.Callback)}">`
end

function Event.Interface.new()
	return setmetatable({}, {
		__index = Event.Prototype,
		__type = Event.Type,
		__tostring = function(self)
			return self:ToString()
		end,
	})
end

return Event.Interface
