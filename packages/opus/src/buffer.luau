--[=[
	@class Opus.Buffer
	@private

	Internal FFI interoperability helpers for the Opus package.
	Wraps `stdPolyfills.ffi` into named operations so higher-level modules never interact with it directly.
]=]

local stdPolyfills = require("../luau_packages/std_polyfills")

local ffi = stdPolyfills.ffi

local OpusBuffer = {}

OpusBuffer.Interface = {}

--[=[
	@within Opus.Buffer
]=]
function OpusBuffer.Interface.alloc(size: number): FFIPointer
	return ffi.alloc(size, 1)
end

--[=[
	@within Opus.Buffer
]=]
function OpusBuffer.Interface.dupe(source: buffer): FFIPointer
	return ffi.dupe(source)
end

--[=[
	@within Opus.Buffer
]=]
function OpusBuffer.Interface.free(pointer: FFIPointer)
	ffi.free(pointer)
end

--[=[
	@within Opus.Buffer

	Reads `length` bytes from `pointer` into a freshly created Luau buffer.
]=]
function OpusBuffer.Interface.read(pointer: FFIPointer, length: number): buffer
	local result = buffer.create(length)
	pointer:read(0, result, 0, length)
	return result
end

--[=[
	@within Opus.Buffer

	Returns a null FFI pointer for optional pointer arguments.
]=]
function OpusBuffer.Interface.getNull(): FFIPointer
	return ffi.getNull()
end

--[=[
	@within Opus.Buffer

	Reads a null-terminated C string from an FFI pointer into a Luau string, up to `maxLength` bytes.
]=]
function OpusBuffer.Interface.fromCString(pointer: FFIPointer, maxLength: number): string
	local chars = table.create(32)
	local offset = 0

	while offset < maxLength do
		local byte = pointer:readu8(offset)

		if byte == 0 then
			break
		end

		chars[#chars + 1] = string.char(byte)
		offset += 1
	end

	return table.concat(chars)
end

return OpusBuffer.Interface
