--[=[
	@class Symphonia.Buffer
	@private

	Internal FFI helpers for the Symphonia package, so the decoder never touches `stdPolyfills.ffi` directly.

	Zune does not write back through a Luau buffer passed as a pointer, so everything libsymphonia writes into (PCM,
	packets, names and error text) is native memory from `alloc`. Inputs (file bytes, paths and extensions) are passed
	as Luau buffers, which Zune reads directly.
]=]

local stdPolyfills = require("../luau_packages/std_polyfills")

local ffi = stdPolyfills.ffi

local SymphoniaBuffer = {}

SymphoniaBuffer.Interface = {}

--[=[
	@within Symphonia.Buffer

	Allocates `size` bytes of native memory from the pooled allocator.
]=]
function SymphoniaBuffer.Interface.alloc(size: number): FFIPointer
	return ffi.alloc(size, 1)
end

--[=[
	@within Symphonia.Buffer

	Returns native memory from `alloc` to the pool.
]=]
function SymphoniaBuffer.Interface.free(pointer: FFIPointer)
	ffi.free(pointer)
end

--[=[
	@within Symphonia.Buffer

	Copies the first `length` bytes at `pointer` into a new Luau buffer.
]=]
function SymphoniaBuffer.Interface.read(pointer: FFIPointer, length: number): buffer
	local result = buffer.create(length)

	pointer:read(0, result, 0, length)

	return result
end

--[=[
	@within Symphonia.Buffer

	Returns the null pointer, for an optional pointer argument left out.
]=]
function SymphoniaBuffer.Interface.getNull(): FFIPointer
	return ffi.getNull()
end

--[=[
	@within Symphonia.Buffer

	Reads the NUL-terminated string at `pointer`, at most `capacity` bytes long.
]=]
function SymphoniaBuffer.Interface.fromCString(pointer: FFIPointer, capacity: number): string
	local text = buffer.tostring(SymphoniaBuffer.Interface.read(pointer, capacity))
	local terminator = string.find(text, "\0", 1, true)

	return if terminator then string.sub(text, 1, terminator - 1) else text
end

--[=[
	@within Symphonia.Buffer

	Returns `text` with a NUL terminator as a Luau buffer, to pass as a C string.
]=]
function SymphoniaBuffer.Interface.cString(text: string): buffer
	return buffer.fromstring(`{text}\0`)
end

return SymphoniaBuffer.Interface
