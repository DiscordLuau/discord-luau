--[=[
	@class Sodium.Chacha20poly1305

	ChaCha20-Poly1305 (IETF, 12-byte nonce) authenticated encryption, detached tag variant.

	Does not require AES-NI and works on all CPUs; for random nonces at scale use `xchacha20poly1305` instead.
	Always use a strict counter nonce and rotate the key before reaching 2^32 messages.
]=]

local Sys = require("../sys")
local Buffer = require("../buffer")

export type EncryptResult = Buffer.EncryptResult

local KEY_BYTES = Sys.chacha20poly1305.KEY_BYTES
local NONCE_BYTES = Sys.chacha20poly1305.NONCE_BYTES
local TAG_BYTES = Sys.chacha20poly1305.TAG_BYTES

local Chacha20poly1305 = {}

Chacha20poly1305.Interface = {}

Chacha20poly1305.Interface.KEY_BYTES = KEY_BYTES
Chacha20poly1305.Interface.NONCE_BYTES = NONCE_BYTES
Chacha20poly1305.Interface.TAG_BYTES = TAG_BYTES

--[=[
	@within Sodium.Chacha20poly1305

	Generates a random 32-byte ChaCha20-Poly1305 key via libsodium's CSPRNG.
]=]
function Chacha20poly1305.Interface.keygen(): buffer
	local keyPointer = Buffer.alloc(KEY_BYTES)

	Sys.lib.crypto_aead_chacha20poly1305_ietf_keygen(keyPointer)

	local key = Buffer.read(keyPointer, KEY_BYTES)
	Sys.lib.sodium_memzero(keyPointer, KEY_BYTES)
	Buffer.free(keyPointer)

	return key
end

--[=[
	@within Sodium.Chacha20poly1305

	Encrypts `plaintext` with `key` (32 bytes) and `nonce` (12 bytes).
	Returns `{ cipher, tag }` where `cipher` is the same length as `plaintext` and `tag` is 16 bytes.
]=]
function Chacha20poly1305.Interface.encrypt(plaintext: buffer, key: buffer, nonce: buffer, ad: buffer?): EncryptResult
	assert(buffer.len(key) == KEY_BYTES, `key must be {KEY_BYTES} bytes, got {buffer.len(key)}`)
	assert(buffer.len(nonce) == NONCE_BYTES, `nonce must be {NONCE_BYTES} bytes, got {buffer.len(nonce)}`)

	local plaintextLength = buffer.len(plaintext)
	local additionalDataLength = if ad then buffer.len(ad) else 0

	local cipherPointer = Buffer.alloc(plaintextLength)
	local tagPointer = Buffer.alloc(TAG_BYTES)
	local plaintextPointer = Buffer.dupe(plaintext)
	local keyPointer = Buffer.dupe(key)
	local noncePointer = Buffer.dupe(nonce)
	local additionalDataPointer = if ad then Buffer.dupe(ad) else Buffer.getNull()
	local nullPointer = Buffer.getNull()

	local result = Sys.lib.crypto_aead_chacha20poly1305_ietf_encrypt_detached(
		cipherPointer,
		tagPointer,
		nullPointer,
		plaintextPointer,
		plaintextLength,
		additionalDataPointer,
		additionalDataLength,
		nullPointer,
		noncePointer,
		keyPointer
	)

	Sys.lib.sodium_memzero(plaintextPointer, plaintextLength)
	Buffer.free(plaintextPointer)
	Sys.lib.sodium_memzero(keyPointer, KEY_BYTES)
	Buffer.free(keyPointer)
	Buffer.free(noncePointer)

	if ad then
		Buffer.free(additionalDataPointer)
	end

	if result ~= 0 then
		Buffer.free(cipherPointer)
		Buffer.free(tagPointer)
		error(`ChaCha20-Poly1305 encryption failed (code={result})`)
	end

	local cipher = Buffer.read(cipherPointer, plaintextLength)
	local tag = Buffer.read(tagPointer, TAG_BYTES)

	Buffer.free(cipherPointer)
	Buffer.free(tagPointer)

	return { cipher = cipher, tag = tag }
end

--[=[
	@within Sodium.Chacha20poly1305

	Decrypts `cipher` using its detached `tag`, `key` (32 bytes), and `nonce` (12 bytes).
	Returns the plaintext buffer; errors if authentication tag does not verify.
]=]
function Chacha20poly1305.Interface.decrypt(
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
	local additionalDataPointer = if ad then Buffer.dupe(ad) else Buffer.getNull()
	local nullPointer = Buffer.getNull()

	local result = Sys.lib.crypto_aead_chacha20poly1305_ietf_decrypt_detached(
		plaintextPointer,
		nullPointer,
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
		Buffer.free(additionalDataPointer)
	end

	if result ~= 0 then
		Sys.lib.sodium_memzero(plaintextPointer, ciphertextLength)
		Buffer.free(plaintextPointer)
		error("ChaCha20-Poly1305 decryption failed: authentication tag mismatch")
	end

	local plaintext = Buffer.read(plaintextPointer, ciphertextLength)
	Sys.lib.sodium_memzero(plaintextPointer, ciphertextLength)
	Buffer.free(plaintextPointer)

	return plaintext
end

return Chacha20poly1305.Interface
