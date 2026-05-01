--[=[
	@class Sodium.Secretbox

	XSalsa20-Poly1305 symmetric authenticated encryption with a shared secret key.
	Both combined (`seal`/`open`) and detached (`sealDetached`/`openDetached`) forms are available.
	Combined: 16-byte MAC prepended to ciphertext. Detached: MAC and ciphertext returned separately as `{ cipher, mac }`.
]=]

local Sys = require("./sys")
local Buffer = require("./buffer")

export type SealResult = Buffer.SealResult

local Secretbox = {}

Secretbox.Interface = {}

--[=[
	@within Sodium.Secretbox

	Generates a random 32-byte secretbox key via libsodium's CSPRNG.
]=]
function Secretbox.Interface.keygen(): buffer
	local keyPointer = Buffer.alloc(Sys.secretbox.KEY_BYTES)

	Sys.lib.crypto_secretbox_keygen(keyPointer)

	local key = Buffer.read(keyPointer, Sys.secretbox.KEY_BYTES)
	Sys.lib.sodium_memzero(keyPointer, Sys.secretbox.KEY_BYTES)
	Buffer.free(keyPointer)

	return key
end

--[=[
	@within Sodium.Secretbox

	Generates a random 24-byte nonce via libsodium's CSPRNG.
	Generate a fresh nonce for every message - never reuse a nonce with the same key.
]=]
function Secretbox.Interface.nonce(): buffer
	local noncePointer = Buffer.alloc(Sys.secretbox.NONCE_BYTES)

	Sys.lib.randombytes_buf(noncePointer, Sys.secretbox.NONCE_BYTES)

	local nonceBytes = Buffer.read(noncePointer, Sys.secretbox.NONCE_BYTES)
	Buffer.free(noncePointer)

	return nonceBytes
end

--[=[
	@within Sodium.Secretbox

	Encrypts `message` with `key` (32 bytes) and `nonce` (24 bytes).
	Returns a combined buffer: `[mac (16 B)][ciphertext]`. Errors if encryption fails.
]=]
function Secretbox.Interface.seal(message: buffer, key: buffer, nonce: buffer): buffer
	assert(buffer.len(key) == Sys.secretbox.KEY_BYTES, `key must be {Sys.secretbox.KEY_BYTES} bytes, got {buffer.len(key)}`)
	assert(buffer.len(nonce) == Sys.secretbox.NONCE_BYTES, `nonce must be {Sys.secretbox.NONCE_BYTES} bytes, got {buffer.len(nonce)}`)

	local messageLength = buffer.len(message)
	local ciphertextLength = Sys.secretbox.MAC_BYTES + messageLength

	local cipherPointer = Buffer.alloc(ciphertextLength)
	local messagePointer = Buffer.dupe(message)
	local keyPointer = Buffer.dupe(key)
	local noncePointer = Buffer.dupe(nonce)

	local result = Sys.lib.crypto_secretbox_easy(cipherPointer, messagePointer, messageLength, noncePointer, keyPointer)

	Sys.lib.sodium_memzero(messagePointer, messageLength)
	Buffer.free(messagePointer)
	Sys.lib.sodium_memzero(keyPointer, Sys.secretbox.KEY_BYTES)
	Buffer.free(keyPointer)
	Buffer.free(noncePointer)

	if result ~= 0 then
		Buffer.free(cipherPointer)
		error(`secretbox seal failed (code={result})`)
	end

	local ciphertext = Buffer.read(cipherPointer, ciphertextLength)
	Buffer.free(cipherPointer)

	return ciphertext
end

--[=[
	@within Sodium.Secretbox

	Decrypts a combined `ciphertext` (produced by `seal`) with `key` and `nonce`.
	Returns the plaintext. Errors if the MAC does not verify.
]=]
function Secretbox.Interface.open(ciphertext: buffer, key: buffer, nonce: buffer): buffer
	assert(buffer.len(key) == Sys.secretbox.KEY_BYTES, `key must be {Sys.secretbox.KEY_BYTES} bytes, got {buffer.len(key)}`)
	assert(buffer.len(nonce) == Sys.secretbox.NONCE_BYTES, `nonce must be {Sys.secretbox.NONCE_BYTES} bytes, got {buffer.len(nonce)}`)

	local ciphertextLength = buffer.len(ciphertext)

	if ciphertextLength < Sys.secretbox.MAC_BYTES then
		error(`secretbox open: ciphertext too short ({ciphertextLength} bytes, minimum {Sys.secretbox.MAC_BYTES})`)
	end

	local messageLength = ciphertextLength - Sys.secretbox.MAC_BYTES

	local plaintextPointer = Buffer.alloc(messageLength)
	local ciphertextPointer = Buffer.dupe(ciphertext)
	local keyPointer = Buffer.dupe(key)
	local noncePointer = Buffer.dupe(nonce)

	local result = Sys.lib.crypto_secretbox_open_easy(
		plaintextPointer,
		ciphertextPointer,
		ciphertextLength,
		noncePointer,
		keyPointer
	)

	Buffer.free(ciphertextPointer)
	Sys.lib.sodium_memzero(keyPointer, Sys.secretbox.KEY_BYTES)
	Buffer.free(keyPointer)
	Buffer.free(noncePointer)

	if result ~= 0 then
		Sys.lib.sodium_memzero(plaintextPointer, messageLength)
		Buffer.free(plaintextPointer)
		error("secretbox open failed: MAC verification failed")
	end

	local plaintext = Buffer.read(plaintextPointer, messageLength)
	Sys.lib.sodium_memzero(plaintextPointer, messageLength)
	Buffer.free(plaintextPointer)

	return plaintext
end

--[=[
	@within Sodium.Secretbox

	Encrypts `message` with `key` (32 bytes) and `nonce` (24 bytes), returning MAC and ciphertext separately.
	Ciphertext is the same length as the message; result is `{ cipher, mac }`. Errors if encryption fails.
]=]
function Secretbox.Interface.sealDetached(message: buffer, key: buffer, nonce: buffer): SealResult
	assert(buffer.len(key) == Sys.secretbox.KEY_BYTES, `key must be {Sys.secretbox.KEY_BYTES} bytes, got {buffer.len(key)}`)
	assert(buffer.len(nonce) == Sys.secretbox.NONCE_BYTES, `nonce must be {Sys.secretbox.NONCE_BYTES} bytes, got {buffer.len(nonce)}`)

	local messageLength = buffer.len(message)

	local cipherPointer = Buffer.alloc(messageLength)
	local macPointer = Buffer.alloc(Sys.secretbox.MAC_BYTES)
	local messagePointer = Buffer.dupe(message)
	local keyPointer = Buffer.dupe(key)
	local noncePointer = Buffer.dupe(nonce)

	local result = Sys.lib.crypto_secretbox_detached(
		cipherPointer,
		macPointer,
		messagePointer,
		messageLength,
		noncePointer,
		keyPointer
	)

	Sys.lib.sodium_memzero(messagePointer, messageLength)
	Buffer.free(messagePointer)
	Sys.lib.sodium_memzero(keyPointer, Sys.secretbox.KEY_BYTES)
	Buffer.free(keyPointer)
	Buffer.free(noncePointer)

	if result ~= 0 then
		Buffer.free(cipherPointer)
		Buffer.free(macPointer)
		error(`secretbox sealDetached failed (code={result})`)
	end

	local cipher = Buffer.read(cipherPointer, messageLength)
	local mac = Buffer.read(macPointer, Sys.secretbox.MAC_BYTES)

	Buffer.free(cipherPointer)
	Buffer.free(macPointer)

	return { cipher = cipher, mac = mac }
end

--[=[
	@within Sodium.Secretbox

	Decrypts `cipher` using its detached `mac`, `key` (32 bytes), and `nonce` (24 bytes).
	Returns the plaintext. Errors if the MAC does not verify.
]=]
function Secretbox.Interface.openDetached(cipher: buffer, mac: buffer, key: buffer, nonce: buffer): buffer
	assert(buffer.len(mac) == Sys.secretbox.MAC_BYTES, `mac must be {Sys.secretbox.MAC_BYTES} bytes, got {buffer.len(mac)}`)
	assert(buffer.len(key) == Sys.secretbox.KEY_BYTES, `key must be {Sys.secretbox.KEY_BYTES} bytes, got {buffer.len(key)}`)
	assert(buffer.len(nonce) == Sys.secretbox.NONCE_BYTES, `nonce must be {Sys.secretbox.NONCE_BYTES} bytes, got {buffer.len(nonce)}`)

	local messageLength = buffer.len(cipher)

	local plaintextPointer = Buffer.alloc(messageLength)
	local cipherPointer = Buffer.dupe(cipher)
	local macPointer = Buffer.dupe(mac)
	local keyPointer = Buffer.dupe(key)
	local noncePointer = Buffer.dupe(nonce)

	local result = Sys.lib.crypto_secretbox_open_detached(
		plaintextPointer,
		cipherPointer,
		macPointer,
		messageLength,
		noncePointer,
		keyPointer
	)

	Buffer.free(cipherPointer)
	Buffer.free(macPointer)
	Sys.lib.sodium_memzero(keyPointer, Sys.secretbox.KEY_BYTES)
	Buffer.free(keyPointer)
	Buffer.free(noncePointer)

	if result ~= 0 then
		Sys.lib.sodium_memzero(plaintextPointer, messageLength)
		Buffer.free(plaintextPointer)
		error("secretbox openDetached failed: MAC verification failed")
	end

	local plaintext = Buffer.read(plaintextPointer, messageLength)
	Sys.lib.sodium_memzero(plaintextPointer, messageLength)
	Buffer.free(plaintextPointer)

	return plaintext
end

return Secretbox.Interface
