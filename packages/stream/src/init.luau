--[=[
	@class Stream
	@__index Prototype

	A Stream is a type of object that can be used to navigate through a string safely, this is used in obscure
		operations such as parsing FormData, JSON and other things.

	Streams are not essential, but they do make things easier as we can avoid tracking the position of a string
		and instead rely on the Stream to peek, advance and so forth.
]=]

--[=[
	@prop textSource string
	@within Stream
]=]

--[=[
	@prop cursorPosition number
	@within Stream
]=]

local Stream = {}

Stream.Interface = {}
Stream.Prototype = {}

--[=[
	@within Stream

	Responsible for peeking further ahead into the stream, without incrementing  the cursor position.
]=]
function Stream.Prototype.peek(self: Stream, length: number?): string?
	if self.cursorPosition + 1 > #self.textSource then
		return nil
	end

	return string.sub(
		self.textSource,
		self.cursorPosition + 1,
		length and self.cursorPosition + length or self.cursorPosition + 1
	)
end

--[=[
	@within Stream

	Responsible for advancing the cursor position of the stream, this will increment the cursor position by the
		amount specified. (defaults to 1)
]=]
function Stream.Prototype.advance(self: Stream, length: number?): string?
	local absoluteLength = length or 1

	if self.cursorPosition + absoluteLength > #self.textSource then
		return nil
	end

	local blockSource = string.sub(self.textSource, self.cursorPosition + 1, self.cursorPosition + absoluteLength)

	self.cursorPosition += absoluteLength

	return blockSource
end

--[=[
	@within Stream

	Responsible for advancing the cursor position of the stream until a predicate is met, this will increment the
		cursor position by the amount specified.
]=]
function Stream.Prototype.advanceUntil(self: Stream, predicate: (char: string) -> ()): string?
	local internalCursor = self.cursorPosition + 1
	local char = string.sub(self.textSource, internalCursor, internalCursor)

	while char and not predicate(char) do
		internalCursor += 1

		if internalCursor > #self.textSource then
			return nil
		end

		char = string.sub(self.textSource, internalCursor, internalCursor)
	end

	local blockSource = string.sub(self.textSource, self.cursorPosition + 1, internalCursor)

	self.cursorPosition = internalCursor

	return blockSource
end

--[=[
	@within Stream

	Will read the stream until the end, this will return the remaining text source.
]=]
function Stream.Prototype.readUntilEnd(self: Stream): string
	local blockSource = string.sub(self.textSource, self.cursorPosition + 1, #self.textSource)

	return blockSource
end

--[=[
	@within Stream

	Trims all whitespaces from the current stream position and onwards
]=]
function Stream.Prototype.trim(self: Stream)
	local peekValue = self:peek()

	while peekValue and string.match(peekValue, "%s") do
		self:advance()

		peekValue = self:peek()
	end
end

--[=[
	@within Stream

	Constructor for the Stream object, will return a new instance of the Stream object.
]=]
function Stream.Interface.new(textSource: string): Stream
	return setmetatable(
		{
			textSource = textSource,
			cursorPosition = 0,
		} :: Stream,
		{
			__index = Stream.Prototype,
		}
	)
end

export type Stream = typeof(Stream.Prototype) & {
	textSource: string,
	cursorPosition: number,
}

return Stream.Interface
