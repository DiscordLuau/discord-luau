local Construct = require("../../../Utils/Construct")

--[=[
	@class Network.Middleware.EventIn

	The `EventIn` class processes incoming events, converting JSON keys to camelCase format for consistency within the application.

	:::caution
	This class is internal and should not be used directly by developers. Instead, use the provided public interfaces and methods to handle incoming events.
	:::
]=]
local EventIn = {}

EventIn.Prototype = {}
EventIn.Interface = {}

EventIn.Prototype.type = "EventIn"

--[=[
	Converts JSON keys from snake_case to camelCase.
	
	@private
	@method toCamelCase
	@param self EventIn
	@param json table -- The JSON object to convert.
	@within Network.Middleware.EventIn
	@return table -- The converted JSON object.
]=]
function EventIn.Prototype.toCamelCase(self: EventIn, json: { [string]: any })
	local source = {}

	for illegalIndex, value in json do
		local legalIndex = string.gsub(illegalIndex, "(_%S)", function(illegal: string)
			return string.upper(string.sub(illegal, 2, 2))
		end)

		if typeof(value) == "table" then
			value = self:toCamelCase(value)
		end

		source[legalIndex] = value
	end

	return source
end

--[=[
	Processes incoming JSON data, converting keys to camelCase if the data is a table.
	
	@private
	@method processJSON
	@param self EventIn
	@param data any -- The data to process.
	@within Network.Middleware.EventIn
	@return any -- The processed data.
]=]
function EventIn.Prototype.processJSON(self: EventIn, data: any)
	if typeof(data) == "table" then
		return self:toCamelCase(data)
	end

	return data
end

--[=[
	Creates a new instance of `EventIn`.
	
	@private
	@method new
	@within Network.Middleware.EventIn
	@return EventIn
]=]
function EventIn.Interface.new()
	return Construct({}, EventIn.Prototype)
end

export type EventIn = typeof(EventIn.Prototype)

return EventIn.Interface
