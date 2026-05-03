--[=[
	@class Dave.Buffer

	Internal FFI interoperability helpers for the Dave package.
]=]

local stdPolyfills = require("../luau_packages/std_polyfills")
local Sys = require("./sys")

local ffi = stdPolyfills.ffi

--[=[
	@within Dave.Buffer
]=]
local function toCString(value: string): FFIPointer
	local length = #value
	local bytes = buffer.create(length + 1)

	buffer.writestring(bytes, 0, value)
	buffer.writeu8(bytes, length, 0)

	return ffi.dupe(bytes)
end

--[=[
	@within Dave.Buffer
]=]
local function fromCString(pointer: FFIPointer): string
	local chars = table.create(32)
	local byteOffset = 0

	while true do
		local byte = pointer:readu8(byteOffset)

		if byte == 0 then
			break
		end

		chars[#chars + 1] = string.char(byte)
		byteOffset += 1
	end

	return table.concat(chars)
end

--[=[
	@within Dave.Buffer
]=]
local function allocateSlot(): FFIPointer
	return ffi.alloc(8, 8)
end

--[=[
	@within Dave.Buffer
]=]
local function readRawU64(value: any): number
	if type(value) == "number" then
		return value
	end

	local rawBuffer = value :: buffer
	local low = buffer.readu32(rawBuffer, 0)
	local high = buffer.readu32(rawBuffer, 4)

	return high * 4294967296 + low
end

--[=[
	@within Dave.Buffer
]=]
local function readSizeT(slot: FFIPointer): number
	return readRawU64(slot:readu64(0))
end

--[=[
	@within Dave.Buffer
]=]
local function readU64AtOffset(pointer: FFIPointer, offset: number): number
	return readRawU64(pointer:readu64(offset))
end

--[=[
	@within Dave.Buffer
]=]
local function readLibBytes(dataSlot: FFIPointer, lengthSlot: FFIPointer): buffer
	local length = readSizeT(lengthSlot)
	local dataPointer = dataSlot:readptr(0)

	if length == 0 then
		Sys.lib.daveFree(dataPointer)
		return buffer.create(0)
	end

	local result = buffer.create(length)
	dataPointer:read(0, result, 0, length)
	Sys.lib.daveFree(dataPointer)

	return result
end

--[=[
	@within Dave.Buffer
]=]
local function u64StringToBuffer(decimal: string): buffer
	local result = buffer.create(8)
	local low = 0
	local high = 0

	for index = 1, #decimal do
		local digit = string.byte(decimal, index) - 48
		local newLow = low * 10 + digit
		local newHigh = high * 10

		if newLow >= 4294967296 then
			newHigh = newHigh + math.floor(newLow / 4294967296)
			newLow = newLow % 4294967296
		end

		low = newLow
		high = newHigh % 4294967296
	end

	buffer.writeu32(result, 0, low)
	buffer.writeu32(result, 4, high)

	return result
end

--[=[
	@within Dave.Buffer
]=]
local function bufferToU64String(bytes: buffer): string
	local low = buffer.readu32(bytes, 0)
	local high = buffer.readu32(bytes, 4)

	if high == 0 then
		return tostring(low)
	end

	local digits = {}

	while high > 0 or low > 0 do
		local highQuotient = math.floor(high / 10)
		local highRemainder = high % 10
		local combined = highRemainder * 4294967296 + low
		local lowQuotient = math.floor(combined / 10)
		local digit = combined % 10

		table.insert(digits, 1, tostring(digit))

		high = highQuotient
		low = lowQuotient
	end

	return table.concat(digits)
end

--[=[
	@within Dave.Buffer
]=]
local function bufferToHex(bytes: buffer): string
	local length = buffer.len(bytes)
	local parts = table.create(length)

	for index = 0, length - 1 do
		parts[index + 1] = string.format("%02x", buffer.readu8(bytes, index))
	end

	return table.concat(parts)
end

--[=[
	@within Dave.Buffer
]=]
local function readPointerBytes(pointer: FFIPointer, lengthValue: any): buffer
	local length = readRawU64(lengthValue)
	local bytes = buffer.create(length)

	pointer:read(0, bytes, 0, length)

	return bytes
end

--[=[
	@within Dave.Buffer
]=]
local function readU64ArrayAndFree(pointerSlot: FFIPointer, lengthSlot: FFIPointer): { string }
	local count = readSizeT(lengthSlot)
	local dataPointer = pointerSlot:readptr(0)
	local results = table.create(count)

	for index = 0, count - 1 do
		local idBuffer = buffer.create(8)
		dataPointer:read(index * 8, idBuffer, 0, 8)
		results[index + 1] = bufferToU64String(idBuffer)
	end

	Sys.lib.daveFree(dataPointer)

	return results
end

--[=[
	@within Dave.Buffer
]=]
local function withCStringArray(ids: { string }, callback: (pointer: FFIPointer, count: number) -> ())
	local count = #ids
	local stringPointers = table.create(count)
	local arrayPointer = ffi.alloc(count * 8, 8)

	for index = 1, count do
		local stringPointer = toCString(ids[index])

		stringPointers[index] = stringPointer
		arrayPointer:writeptr((index - 1) * 8, stringPointer)
	end

	callback(arrayPointer, count)

	ffi.free(arrayPointer)

	for _, stringPointer in stringPointers do
		ffi.free(stringPointer)
	end
end

return {
	toCString = toCString,
	fromCString = fromCString,
	allocateSlot = allocateSlot,
	readRawU64 = readRawU64,
	readSizeT = readSizeT,
	readU64AtOffset = readU64AtOffset,
	readLibBytes = readLibBytes,
	u64StringToBuffer = u64StringToBuffer,
	bufferToU64String = bufferToU64String,
	bufferToHex = bufferToHex,
	readPointerBytes = readPointerBytes,
	readU64ArrayAndFree = readU64ArrayAndFree,
	withCStringArray = withCStringArray,
}
