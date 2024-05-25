local Construct = require("../../../Utils/Construct")

--[=[
	@class Network.Middleware.EventOut

	The `EventOut` class processes outgoing events. Currently, it acts as a placeholder for any future processing that may be required for outgoing JSON data.

	:::caution
	This class is internal and should not be used directly by developers. Instead, use the provided public interfaces and methods to handle outgoing events.
	:::
]=]
local EventOut = {}

EventOut.Prototype = {}
EventOut.Interface = {}

EventOut.Prototype.type = "EventOut"

--[=[
	Processes outgoing JSON data. Currently, this method returns the data unchanged.
	
	@private
	@method processJSON
	@param self EventOut
	@param data any -- The data to process.
	@within Network.Middleware.EventOut
	@return any -- The processed data.
]=]
function EventOut.Prototype.processJSON(_: EventOut, data: any)
	return data
end

--[=[
	Creates a new instance of `EventOut`.
	
	@private
	@method new
	@within Network.Middleware.EventOut
	@return EventOut
]=]
function EventOut.Interface.new()
	return Construct({}, EventOut.Prototype)
end

export type EventOut = typeof(EventOut.Prototype)

return EventOut.Interface
