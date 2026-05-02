--[=[
	@class Accumulator
	@__index Prototype

	An accumulator is a data structure that collects data written to it in a sequential manner,
	only exposing that data once it has been completely written.

	It is used in the Discord Websocket to ensure that we receive an entire ZLib compressed
	message before we attempt to decompress it.
]=]

local Accumulator = {}

Accumulator.Interface = {}
Accumulator.Prototype = {}

--[=[
	@within Accumulator

	Appends data to the accumulator.
]=]
function Accumulator.Prototype.write(self: Accumulator, data: string)
	self.data ..= data
end

--[=[
	@within Accumulator

	Returns the currently accumulated data without clearing it.
]=]
function Accumulator.Prototype.peek(self: Accumulator): string
	return self.data
end

--[=[
	@within Accumulator

	Returns the number of bytes currently accumulated.
]=]
function Accumulator.Prototype.size(self: Accumulator): number
	return #self.data
end

--[=[
	@within Accumulator

	Returns all accumulated data and clears the accumulator.
]=]
function Accumulator.Prototype.flush(self: Accumulator): string
	local data = self.data

	self.data = ""

	return data
end

--[=[
	@within Accumulator

	Constructor for the Accumulator object, will return a new instance of the Accumulator object.
]=]
function Accumulator.Interface.new(): Accumulator
	return setmetatable(
		{
			data = "",
		} :: Accumulator,
		{
			__index = Accumulator.Prototype,
		}
	)
end

export type Accumulator = typeof(Accumulator.Prototype) & {
	data: string,
}

return Accumulator.Interface
