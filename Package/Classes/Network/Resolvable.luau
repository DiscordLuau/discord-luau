local Construct = require("@Utils/Construct")

local ResolvableType = require("@Enums/ResolveableType")

local EventOut = require("@Network/Middleware/EventOut")
local EventIn = require("@Network/Middleware/EventIn")

--[=[
	@class Network.Resolvable

	The `Resolvable` class manages the scheduling of HTTP tasks. It allows for the addition, removal, and execution of tasks at a specified frequency.

	:::caution
	This class is internal and should not be used directly by developers. Instead, use the provided public interfaces and methods to manage HTTP scheduling.
	:::
]=]
local Resolvable = {}

Resolvable.Prototype = {}
Resolvable.Interface = {}

Resolvable.Prototype.type = "Resolvable"

--[=[
	Returns a dictionary of headers this resolvable requires in order to successfuly be processed by the Discord API

	@private
	@method headers
	@within Network.Resolvable
	@return { [string]: string }
]=]
function Resolvable.Prototype.headers(self: Resolvable): { [string]: string }
	return self.metadata and self.metadata.headers or {}
end

--[=[
	Resolves the data that this Resolvable has, for instance - if this data is JSON, it will be thrown through the EventIn pre-processor.

	@private
	@method resolve
	@within Network.Resolvable
	@return any
]=]
function Resolvable.Prototype.resolve(self: Resolvable, toCamelCase: boolean?)
	if self.type == ResolvableType.JSON then
		return toCamelCase and self.eventInMiddleware:processJSON(self.data)
			or self.eventOutMiddleware:processJSON(self.data)
	end

	return self.data
end

--[=[
	Allows mutation of the data held in the resolvable

	@private
	@method update
	@within Network.Resolvable
	@return any
]=]
function Resolvable.Prototype.update(self: Resolvable, callback: (data: any) -> any)
	self.data = callback(self.data)

	return self
end

--[=[
	Creates a new instance of `Resolvable`.
	
	@private
	@function new
	@param threadCount number? -- The number of worker threads to spawn.
	@within Network.Resolvable
	@return Resolvable
]=]
function Resolvable.Interface.new(
	type: string,
	data: any,
	metadata: {
		headers: { [string]: string },
		attachments: { any },
	}?
): Resolvable
	local self = (
		Construct({
			data = data,
			type = type,

			eventOutMiddleware = EventOut.new(),
			eventInMiddleware = EventIn.new(),

			metadata = metadata or {
				headers = {},
				attachments = {},
			},
		}, Resolvable.Prototype) :: unknown
	) :: Resolvable

	return self
end

export type Resolvable = typeof(Resolvable.Prototype) & {
	data: any,
	type: ResolvableType.ResolveableType,

	eventOutMiddleware: EventOut.EventOut,
	eventInMiddleware: EventIn.EventIn,

	metadata: {
		headers: { [string]: string },
		attachments: { any },
	},
}

return Resolvable.Interface
