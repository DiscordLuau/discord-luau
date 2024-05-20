local Construct = require("../../../Utils/Construct")

--[=[
	@class Middleware.EventOut

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
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

export type EventOut = typeof(EventOut.Prototype)

return EventOut.Interface