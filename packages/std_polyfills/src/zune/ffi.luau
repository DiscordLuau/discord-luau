--[=[
	@class StdPolyfills.zune.ffi
	@private

	Zune's `zune.ffi` with pooled native memory.

	Zune caches pointer objects by address. `zune.ffi.free` returns the memory to the allocator but leaves the
	dead pointer object in that cache until the garbage collector removes it, and a native library that later
	receives the same address from `malloc` (a libopus decoder, a libdave session) is handed the dead object
	and fails with "unavailable address". Memory freed here therefore goes back to a pool that `alloc` and
	`dupe` reuse, so it never returns to the allocator and no dead object ever shadows a live address. The
	pool holds at most the peak amount allocated at once.
]=]

local MINIMUM_SIZE_CLASS = 64

-- selene: allow(undefined_variable)
local zuneFfi = zune.ffi

local pooledPointers: { [string]: { FFIPointer } } = {}
local poolKeyByPointer: { [FFIPointer]: string } = {}
local freedPointers: { [FFIPointer]: boolean } = {}
local zeroBuffers: { [number]: buffer } = {}

local function sizeClassFor(size: number): number
	local sizeClass = MINIMUM_SIZE_CLASS

	while sizeClass < size do
		sizeClass *= 2
	end

	return sizeClass
end

local function zeroBufferFor(sizeClass: number): buffer
	local zeros = zeroBuffers[sizeClass] or buffer.create(sizeClass)

	zeroBuffers[sizeClass] = zeros

	return zeros
end

local function alloc(size: number, alignment: number?): FFIPointer
	local sizeClass = sizeClassFor(size)
	local poolKey = `{sizeClass}:{alignment or 1}`
	local pool = pooledPointers[poolKey]
	local reused = pool and table.remove(pool)

	if reused then
		reused:tag(0)
		reused:write(0, zeroBufferFor(sizeClass), 0, sizeClass)
		freedPointers[reused] = nil

		return reused
	end

	local pointer = zuneFfi.alloc(sizeClass, alignment)

	poolKeyByPointer[pointer] = poolKey

	return pointer
end

local function dupe(source: buffer | FFIPointer | vector): FFIPointer
	if typeof(source) ~= "buffer" then
		return zuneFfi.dupe(source)
	end

	local length = buffer.len(source)
	local pointer = alloc(length, 1)

	pointer:write(0, source, 0, length)

	return pointer
end

local function free(pointer: FFIPointer)
	local poolKey = poolKeyByPointer[pointer]
	local pool = pooledPointers[poolKey] or {}

	if not poolKey then
		zuneFfi.free(pointer)

		return
	end

	if freedPointers[pointer] then
		error("Double free", 2)
	end

	freedPointers[pointer] = true
	pooledPointers[poolKey] = pool

	table.insert(pool, pointer)
end

return setmetatable({
	alloc = alloc,
	dupe = dupe,
	free = free,
}, { __index = zuneFfi })
