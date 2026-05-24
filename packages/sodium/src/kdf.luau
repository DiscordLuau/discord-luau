--[=[
	@class Sodium.Kdf

	BLAKE2b-based key derivation - derives independent subkeys from a single master key.
	Each subkey is identified by a numeric ID and an 8-character ASCII context string.
	The context namespaces subkeys within the master key; use distinct contexts per subsystem.
	Shorter contexts are zero-padded to 8 bytes; longer contexts will error.
]=]

local Sys = require("./sys")
local Buffer = require("./buffer")

local function makeContext(context: string): FFIPointer
	if #context < 1 or #context > Sys.kdf.CONTEXT_BYTES then
		error(`kdf context must be 1–{Sys.kdf.CONTEXT_BYTES} characters, got {#context}`)
	end

	local buf = buffer.create(Sys.kdf.CONTEXT_BYTES)
	buffer.writestring(buf, 0, context)

	return Buffer.dupe(buf)
end

local Kdf = {}

Kdf.Interface = {}

--[=[
	@within Sodium.Kdf

	Generates a random 32-byte master key via libsodium's CSPRNG.
]=]
function Kdf.Interface.keygen(): buffer
	local keyPointer = Buffer.alloc(Sys.kdf.KEY_BYTES)

	Sys.lib.crypto_kdf_keygen(keyPointer)

	local key = Buffer.read(keyPointer, Sys.kdf.KEY_BYTES)
	Sys.lib.sodium_memzero(keyPointer, Sys.kdf.KEY_BYTES)
	Buffer.free(keyPointer)

	return key
end

--[=[
	@within Sodium.Kdf

	Derives a subkey from `masterKey` (32 bytes) identified by `subkeyId` and an 8-char `context` string.
	`outputBytes` controls the subkey length (16–64, default 32); errors if `context` or `outputBytes` is out of range.
]=]
function Kdf.Interface.deriveKey(masterKey: buffer, subkeyId: number, context: string, outputBytes: number?): buffer
	local outputLength = outputBytes or Sys.kdf.KEY_BYTES
	assert(
		outputLength >= Sys.kdf.BYTES_MIN and outputLength <= Sys.kdf.BYTES_MAX,
		`outputBytes must be {Sys.kdf.BYTES_MIN}–{Sys.kdf.BYTES_MAX}, got {outputLength}`
	)
	assert(
		buffer.len(masterKey) == Sys.kdf.KEY_BYTES,
		`masterKey must be {Sys.kdf.KEY_BYTES} bytes, got {buffer.len(masterKey)}`
	)

	local subkeyPointer = Buffer.alloc(outputLength)
	local contextPointer = makeContext(context)
	local keyPointer = Buffer.dupe(masterKey)

	local result = Sys.lib.crypto_kdf_derive_from_key(subkeyPointer, outputLength, subkeyId, contextPointer, keyPointer)

	Buffer.free(contextPointer)
	Sys.lib.sodium_memzero(keyPointer, Sys.kdf.KEY_BYTES)
	Buffer.free(keyPointer)

	if result ~= 0 then
		Sys.lib.sodium_memzero(subkeyPointer, outputLength)
		Buffer.free(subkeyPointer)
		error(`kdf deriveKey failed (code={result})`)
	end

	local subkey = Buffer.read(subkeyPointer, outputLength)
	Sys.lib.sodium_memzero(subkeyPointer, outputLength)
	Buffer.free(subkeyPointer)

	return subkey
end

return Kdf.Interface
