--[=[
	@class Buffer
	@__index Prototype

	A buffer is a data structure that is used to store data in a sequential manner, only 
		allowed to access that data once it has been completely written to the buffer.

	It is used in th Discord Websocket to ensure that we receive an entire ZLib compressed
		message before we attempt to decompress it.
]=]

local Buffer = {}

Buffer.Interface = {}
Buffer.Prototype = {}

--[=[
	@within Buffer

	Responsible for writing data to the buffer.
]=]
function Buffer.Prototype.write(self: Buffer, data: string)
	self.data ..= data
end

--[=[
	@within Buffer

	Responsible for flushing the data from the buffer and returning it.
]=]
function Buffer.Prototype.flush(self: Buffer): string
	local data = self.data

	self.data = ""

	return data
end

--[=[
	@within Buffer

	Constructor for the Buffer object, will return a new instance of the Buffer object.
]=]
function Buffer.Interface.new(): Buffer
	return setmetatable(
		{
			data = "",
		} :: Buffer,
		{
			__index = Buffer.Prototype,
		}
	)
end

export type Buffer = typeof(Buffer.Prototype) & {
	data: string,
}

return Buffer.Interface
