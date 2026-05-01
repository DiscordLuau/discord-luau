--[=[
	@class Sodium.Auth

	HMAC-SHA512256 symmetric MAC - produces and verifies 32-byte authentication tags.
	The verification step runs in constant time to prevent timing attacks.
	Both parties must share the same secret key; use an AEAD module for encrypted messages.
]=]

local Sys = require("./sys")
local Buffer = require("./buffer")

local Auth = {}

Auth.Interface = {}

--[=[
	@within Sodium.Auth

	Generates a random 32-byte authentication key via libsodium's CSPRNG.
]=]
function Auth.Interface.keygen(): buffer
	local keyPointer = Buffer.alloc(Sys.auth.KEY_BYTES)

	Sys.lib.crypto_auth_keygen(keyPointer)

	local key = Buffer.read(keyPointer, Sys.auth.KEY_BYTES)
	Sys.lib.sodium_memzero(keyPointer, Sys.auth.KEY_BYTES)
	Buffer.free(keyPointer)

	return key
end

--[=[
	@within Sodium.Auth

	Computes a 32-byte HMAC-SHA512256 authentication tag for `message` under `key`.
]=]
function Auth.Interface.sign(message: buffer, key: buffer): buffer
	assert(buffer.len(key) == Sys.auth.KEY_BYTES, `key must be {Sys.auth.KEY_BYTES} bytes, got {buffer.len(key)}`)

	local messageLength = buffer.len(message)
	local outputPointer = Buffer.alloc(Sys.auth.BYTES)
	local inputPointer = Buffer.dupe(message)
	local keyPointer = Buffer.dupe(key)

	local result = Sys.lib.crypto_auth(outputPointer, inputPointer, messageLength, keyPointer)

	Buffer.free(inputPointer)
	Sys.lib.sodium_memzero(keyPointer, Sys.auth.KEY_BYTES)
	Buffer.free(keyPointer)

	if result ~= 0 then
		Buffer.free(outputPointer)
		error(`auth sign failed (code={result})`)
	end

	local mac = Buffer.read(outputPointer, Sys.auth.BYTES)

	Buffer.free(outputPointer)

	return mac
end

--[=[
	@within Sodium.Auth

	Verifies `mac` against `message` under `key` in constant time.
	Returns `true` if valid, `false` otherwise - does not error on failed verification.
]=]
function Auth.Interface.verify(mac: buffer, message: buffer, key: buffer): boolean
	assert(buffer.len(mac) == Sys.auth.BYTES, `mac must be {Sys.auth.BYTES} bytes, got {buffer.len(mac)}`)
	assert(buffer.len(key) == Sys.auth.KEY_BYTES, `key must be {Sys.auth.KEY_BYTES} bytes, got {buffer.len(key)}`)

	local messageLength = buffer.len(message)
	local macPointer = Buffer.dupe(mac)
	local inputPointer = Buffer.dupe(message)
	local keyPointer = Buffer.dupe(key)

	local result = Sys.lib.crypto_auth_verify(macPointer, inputPointer, messageLength, keyPointer)

	Buffer.free(macPointer)
	Buffer.free(inputPointer)
	Sys.lib.sodium_memzero(keyPointer, Sys.auth.KEY_BYTES)
	Buffer.free(keyPointer)

	return result == 0
end

return Auth.Interface
