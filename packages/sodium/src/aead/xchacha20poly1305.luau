--[=[
	@class Sodium.Xchacha20poly1305

	XChaCha20-Poly1305 (24-byte nonce) authenticated encryption, detached tag variant.

	Extends ChaCha20-Poly1305 with a 192-bit nonce, making random nonce generation safe at any scale.
	Requires no hardware acceleration and runs at constant time on all CPUs.
]=]

local Sys = require("../sys")
local Buffer = require("../buffer")

export type EncryptResult = Buffer.EncryptResult

local KEY_BYTES = Sys.xchacha20poly1305.KEY_BYTES
local NONCE_BYTES = Sys.xchacha20poly1305.NONCE_BYTES
local TAG_BYTES = Sys.xchacha20poly1305.TAG_BYTES

local Xchacha20poly1305 = {}

Xchacha20poly1305.Interface = {}

Xchacha20poly1305.Interface.KEY_BYTES = KEY_BYTES
Xchacha20poly1305.Interface.NONCE_BYTES = NONCE_BYTES
Xchacha20poly1305.Interface.TAG_BYTES = TAG_BYTES

--[=[
	@within Sodium.Xchacha20poly1305

	Generates a random 32-byte XChaCha20-Poly1305 key via libsodium's CSPRNG.
]=]
function Xchacha20poly1305.Interface.keygen(): buffer
	local keyPointer = Buffer.alloc(KEY_BYTES)

	Sys.lib.crypto_aead_xchacha20poly1305_ietf_keygen(keyPointer)

	local key = Buffer.read(keyPointer, KEY_BYTES)
	Sys.lib.sodium_memzero(keyPointer, KEY_BYTES)
	Buffer.free(keyPointer)

	return key
end

--[=[
	@within Sodium.Xchacha20poly1305

	Encrypts `plaintext` with `key` (32 bytes) and `nonce` (24 bytes).
	Returns `{ cipher, tag }` where `cipher` is the same length as `plaintext` and `tag` is 16 bytes.
]=]
function Xchacha20poly1305.Interface.encrypt(plaintext: buffer, key: buffer, nonce: buffer, ad: buffer?): EncryptResult
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

	local result = Sys.lib.crypto_aead_xchacha20poly1305_ietf_encrypt_detached(
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
		error(`XChaCha20-Poly1305 encryption failed (code={result})`)
	end

	local cipher = Buffer.read(cipherPointer, plaintextLength)
	local tag = Buffer.read(tagPointer, TAG_BYTES)

	Buffer.free(cipherPointer)
	Buffer.free(tagPointer)

	return { cipher = cipher, tag = tag }
end

--[=[
	@within Sodium.Xchacha20poly1305

	Decrypts `cipher` using its detached `tag`, `key` (32 bytes), and `nonce` (24 bytes).
	Returns the plaintext buffer; errors if authentication tag does not verify.
]=]
function Xchacha20poly1305.Interface.decrypt(
	cipher: buffer,
	tag: buffer,
	key: buffer,
	nonce: buffer,
	ad: buffer?
): buffer
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

	local result = Sys.lib.crypto_aead_xchacha20poly1305_ietf_decrypt_detached(
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
		error("XChaCha20-Poly1305 decryption failed: authentication tag mismatch")
	end

	local plaintext = Buffer.read(plaintextPointer, ciphertextLength)
	Sys.lib.sodium_memzero(plaintextPointer, ciphertextLength)
	Buffer.free(plaintextPointer)

	return plaintext
end

return Xchacha20poly1305.Interface
