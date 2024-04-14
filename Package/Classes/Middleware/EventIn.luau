local Construct = require("../../Utils/Construct")

--[=[
	@class Internal.EventIn

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local EventIn = {}

EventIn.Prototype = {}
EventIn.Interface = {}

EventIn.Prototype.type = "EventIn"

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

function EventIn.Prototype.processJSON(self: EventIn, data: any)
	if typeof(data) == "table" then
		return self:toCamelCase(data)
	end

	return data
end

function EventIn.Interface.new()
	return Construct({ }, EventIn.Prototype)
end

export type EventIn = typeof(EventIn.Interface.new())

return EventIn.Interface