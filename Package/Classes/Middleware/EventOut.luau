local Construct = require("../../Utils/Construct")

local EventOut = {}

EventOut.Prototype = {}
EventOut.Interface = {}

EventOut.Prototype.type = "EventOut"

function EventOut.Prototype.processJSON(self: EventOut, data: any)
	return data
end

function EventOut.Interface.new()
	return Construct({ }, EventOut.Prototype)
end

export type EventOut = typeof(EventOut.Interface.new())

return EventOut.Interface