--[=[
	@class Sodium.Generichash

	BLAKE2b hashing with variable output length (16–64 bytes), optional key, and streaming support.
	Can be used unkeyed (like SHA-256) or keyed (as a MAC).
	One-shot (`hash`): hashes a buffer in a single call.
	Streaming (`new` → `update` → `final`): hashes data incrementally; `final` may only be called once.
]=]

local Sys = require("./sys")
local Buffer = require("./buffer")

--[=[
	@class Sodium.Generichash.State
	@__index Prototype

	Incremental BLAKE2b hash state; created via `generichash.new()`.
	Feed data incrementally with `update`, then call `final` exactly once to retrieve the digest.
	Always call `final` - the internal FFI buffer cannot be reclaimed by the GC if it is skipped,
	even when all references to the State are dropped.
]=]

--[=[
	@prop statePointer FFIPointer
	@within Sodium.Generichash.State
]=]

--[=[
	@prop outputBytes number
	@within Sodium.Generichash.State
]=]

--[=[
	@prop finalized boolean
	@within Sodium.Generichash.State
]=]

local stateBytes

local State = {}

State.Interface = {}
State.Prototype = {}

--[=[
	@within Sodium.Generichash.State

	Feeds `chunk` into the hash state. May be called any number of times before `final`.
	Errors if called after `final`.
]=]
function State.Prototype.update(self: State, chunk: buffer)
	if self.finalized then
		error("generichash State:update() called after final()")
	end

	local chunkPointer = Buffer.dupe(chunk)

	local result = Sys.lib.crypto_generichash_update(self.statePointer, chunkPointer, buffer.len(chunk))

	Buffer.free(chunkPointer)

	if result ~= 0 then
		self.finalized = true
		Sys.lib.sodium_memzero(self.statePointer, stateBytes)
		Buffer.free(self.statePointer)
		self.statePointer = nil :: any
		error(`generichash State:update failed (code={result})`)
	end
end

--[=[
	@within Sodium.Generichash.State

	Finalises the hash and returns the digest. Frees the internal state buffer.
	Errors if called more than once on the same `State`.
]=]
function State.Prototype.final(self: State): buffer
	if self.finalized then
		error("generichash State:final() called more than once")
	end

	self.finalized = true

	local outputPointer = Buffer.alloc(self.outputBytes)

	local result = Sys.lib.crypto_generichash_final(self.statePointer, outputPointer, self.outputBytes)

	Sys.lib.sodium_memzero(self.statePointer, stateBytes)
	Buffer.free(self.statePointer)
	self.statePointer = nil :: any

	if result ~= 0 then
		Buffer.free(outputPointer)
		error(`generichash State:final failed (code={result})`)
	end

	local digest = Buffer.read(outputPointer, self.outputBytes)

	Buffer.free(outputPointer)

	return digest
end

--[=[
	@within Sodium.Generichash.State
]=]
function State.Interface.new(outputBytes: number?, key: buffer?): State
	local outputLength = outputBytes or Sys.generichash.BYTES

	assert(
		outputLength >= Sys.generichash.BYTES_MIN and outputLength <= Sys.generichash.BYTES_MAX,
		`outputBytes must be {Sys.generichash.BYTES_MIN}–{Sys.generichash.BYTES_MAX}, got {outputLength}`
	)

	if key then
		local keyLength = buffer.len(key)
		assert(
			keyLength >= Sys.generichash.KEY_BYTES_MIN and keyLength <= Sys.generichash.KEY_BYTES_MAX,
			`key must be {Sys.generichash.KEY_BYTES_MIN}–{Sys.generichash.KEY_BYTES_MAX} bytes, got {keyLength}`
		)
	end

	if not stateBytes then
		stateBytes = Buffer.readRawU64(Sys.lib.crypto_generichash_statebytes())
	end

	local keyLength = if key then buffer.len(key) else 0
	local keyPointer = if key then Buffer.dupe(key) else Buffer.getNull()
	local statePointer = Buffer.alloc(stateBytes)

	local result = Sys.lib.crypto_generichash_init(statePointer, keyPointer, keyLength, outputLength)

	if key then
		Sys.lib.sodium_memzero(keyPointer, keyLength)
		Buffer.free(keyPointer)
	end

	if result ~= 0 then
		Sys.lib.sodium_memzero(statePointer, stateBytes)
		Buffer.free(statePointer)
		error(`generichash State init failed (code={result})`)
	end

	return setmetatable(
		{
			statePointer = statePointer,
			outputBytes = outputLength,
			finalized = false,
		} :: State,
		{ __index = State.Prototype }
	)
end

export type State = typeof(State.Prototype) & {
	statePointer: FFIPointer,
	outputBytes: number,
	finalized: boolean,
}

local Generichash = {}

Generichash.Interface = {}

--[=[
	@within Sodium.Generichash

	Hashes `message` in one call and returns a digest of `outputBytes` bytes (default 32, range 16–64).
	Optionally accepts a `key` (16–64 bytes) to produce a keyed BLAKE2b digest.
]=]
function Generichash.Interface.hash(message: buffer, outputBytes: number?, key: buffer?): buffer
	local outputLength = outputBytes or Sys.generichash.BYTES
	assert(
		outputLength >= Sys.generichash.BYTES_MIN and outputLength <= Sys.generichash.BYTES_MAX,
		`outputBytes must be {Sys.generichash.BYTES_MIN}–{Sys.generichash.BYTES_MAX}, got {outputLength}`
	)
	if key then
		local keyLength = buffer.len(key)
		assert(
			keyLength >= Sys.generichash.KEY_BYTES_MIN and keyLength <= Sys.generichash.KEY_BYTES_MAX,
			`key must be {Sys.generichash.KEY_BYTES_MIN}–{Sys.generichash.KEY_BYTES_MAX} bytes, got {keyLength}`
		)
	end

	local keyLength = if key then buffer.len(key) else 0
	local outputPointer = Buffer.alloc(outputLength)
	local inputPointer = Buffer.dupe(message)
	local keyPointer = if key then Buffer.dupe(key) else Buffer.getNull()

	local result = Sys.lib.crypto_generichash(
		outputPointer,
		outputLength,
		inputPointer,
		buffer.len(message),
		keyPointer,
		keyLength
	)

	Buffer.free(inputPointer)

	if key then
		Sys.lib.sodium_memzero(keyPointer, keyLength)
		Buffer.free(keyPointer)
	end

	if result ~= 0 then
		Buffer.free(outputPointer)
		error(`generichash failed (code={result})`)
	end

	local digest = Buffer.read(outputPointer, outputLength)

	Buffer.free(outputPointer)

	return digest
end

Generichash.Interface.new = State.Interface.new

return Generichash.Interface
