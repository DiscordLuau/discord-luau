--[=[
	@class Sodium.Aes256gcm

	AES-256-GCM authenticated encryption, detached tag variant.

	Requires AES-NI hardware support - call isAvailable() before use; libsodium will abort on CPUs without it.
	Uses a 12-byte nonce; always use a strict counter and rotate the key before reaching 2^32.
]=]

local Sys = require("../sys")
local Buffer = require("../buffer")

export type EncryptResult = Buffer.EncryptResult

local KEY_BYTES = Sys.aes256gcm.KEY_BYTES
local NONCE_BYTES = Sys.aes256gcm.NONCE_BYTES
local TAG_BYTES = Sys.aes256gcm.TAG_BYTES

local Aes256gcm = {}

Aes256gcm.Interface = {}

Aes256gcm.Interface.KEY_BYTES = KEY_BYTES
Aes256gcm.Interface.NONCE_BYTES = NONCE_BYTES
Aes256gcm.Interface.TAG_BYTES = TAG_BYTES

--[=[
	@within Sodium.Aes256gcm

	Returns true if the current CPU supports AES-NI hardware acceleration.
]=]
function Aes256gcm.Interface.isAvailable(): boolean
	return Sys.lib.crypto_aead_aes256gcm_is_available() == 1
end

--[=[
	@within Sodium.Aes256gcm

	Generates a random 32-byte AES-256-GCM key via libsodium's CSPRNG.
]=]
function Aes256gcm.Interface.keygen(): buffer
	local keyPointer = Buffer.alloc(KEY_BYTES)

	Sys.lib.crypto_aead_aes256gcm_keygen(keyPointer)

	local key = Buffer.read(keyPointer, KEY_BYTES)
	Sys.lib.sodium_memzero(keyPointer, KEY_BYTES)
	Buffer.free(keyPointer)

	return key
end

--[=[
	@within Sodium.Aes256gcm

	Encrypts `plaintext` with `key` (32 bytes) and `nonce` (12 bytes).
	Returns `{ cipher, tag }` where `cipher` is the same length as `plaintext` and `tag` is 16 bytes.
]=]
function Aes256gcm.Interface.encrypt(plaintext: buffer, key: buffer, nonce: buffer, ad: buffer?): EncryptResult
	assert(buffer.len(key) == KEY_BYTES, `key must be {KEY_BYTES} bytes, got {buffer.len(key)}`)
	assert(buffer.len(nonce) == NONCE_BYTES, `nonce must be {NONCE_BYTES} bytes, got {buffer.len(nonce)}`)

	local plaintextLength = buffer.len(plaintext)
	local additionalDataLength = if ad then buffer.len(ad) else 0

	local cipherPointer = Buffer.alloc(plaintextLength)
	local tagPointer = Buffer.alloc(TAG_BYTES)
	local plaintextPointer = Buffer.dupe(plaintext)
	local keyPointer = Buffer.dupe(key)
	local noncePointer = Buffer.dupe(nonce)
	local additionalDataPointer = if ad then Buffer.dupe(ad) else nil

	local result = Sys.lib.crypto_aead_aes256gcm_encrypt_detached(
		cipherPointer,
		tagPointer,
		nil,
		plaintextPointer,
		plaintextLength,
		additionalDataPointer,
		additionalDataLength,
		nil,
		noncePointer,
		keyPointer
	)

	Sys.lib.sodium_memzero(plaintextPointer, plaintextLength)
	Buffer.free(plaintextPointer)
	Sys.lib.sodium_memzero(keyPointer, KEY_BYTES)
	Buffer.free(keyPointer)
	Buffer.free(noncePointer)

	if ad then
		Buffer.free(additionalDataPointer :: FFIPointer)
	end

	if result ~= 0 then
		Buffer.free(cipherPointer)
		Buffer.free(tagPointer)
		error(`AES-256-GCM encryption failed (code={result})`)
	end

	local cipher = Buffer.read(cipherPointer, plaintextLength)
	local tag = Buffer.read(tagPointer, TAG_BYTES)

	Buffer.free(cipherPointer)
	Buffer.free(tagPointer)

	return { cipher = cipher, tag = tag }
end

--[=[
	@within Sodium.Aes256gcm

	Decrypts `cipher` using its detached `tag`, `key` (32 bytes), and `nonce` (12 bytes).
	Returns the plaintext buffer; errors if authentication tag does not verify.
]=]
function Aes256gcm.Interface.decrypt(cipher: buffer, tag: buffer, key: buffer, nonce: buffer, ad: buffer?): buffer
	assert(buffer.len(tag) == TAG_BYTES, `tag must be {TAG_BYTES} bytes, got {buffer.len(tag)}`)
	assert(buffer.len(key) == KEY_BYTES, `key must be {KEY_BYTES} bytes, got {buffer.len(key)}`)
	assert(buffer.len(nonce) == NONCE_BYTES, `nonce must be {NONCE_BYTES} bytes, got {buffer.len(nonce)}`)

	local ciphertextLength = buffer.len(cipher)
	local additionalDataLength = if ad then buffer.len(ad) else 0

	local plaintextPointer = Buffer.alloc(ciphertextLength)
	local cipherPointer = Buffer.dupe(cipher)
	local tagPointer = Buffer.dupe(tag)
	local keyPointer = Buffer.dupe(key)
	local noncePointer = Buffer.dupe(nonce)
	local additionalDataPointer = if ad then Buffer.dupe(ad) else nil

	local result = Sys.lib.crypto_aead_aes256gcm_decrypt_detached(
		plaintextPointer,
		nil,
		cipherPointer,
		ciphertextLength,
		tagPointer,
		additionalDataPointer,
		additionalDataLength,
		noncePointer,
		keyPointer
	)

	Buffer.free(cipherPointer)
	Buffer.free(tagPointer)
	Sys.lib.sodium_memzero(keyPointer, KEY_BYTES)
	Buffer.free(keyPointer)
	Buffer.free(noncePointer)

	if ad then
		Buffer.free(additionalDataPointer :: FFIPointer)
	end

	if result ~= 0 then
		Sys.lib.sodium_memzero(plaintextPointer, ciphertextLength)
		Buffer.free(plaintextPointer)
		error("AES-256-GCM decryption failed: authentication tag mismatch")
	end

	local plaintext = Buffer.read(plaintextPointer, ciphertextLength)
	Sys.lib.sodium_memzero(plaintextPointer, ciphertextLength)
	Buffer.free(plaintextPointer)

	return plaintext
end

return Aes256gcm.Interface
