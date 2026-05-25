--[=[
	@class Sodium.Box

	X25519 + XSalsa20-Poly1305 public-key authenticated encryption.
	Encrypts from sender secret key to recipient public key; only the recipient can decrypt.
	Both parties must know each other's public key; call `precompute` once per recipient
	to derive a shared key and avoid repeated Diffie-Hellman for multiple messages.
]=]

local Sys = require("./sys")
local Buffer = require("./buffer")

export type Keypair = Buffer.Keypair
export type SealResult = Buffer.SealResult

local Box = {}

Box.Interface = {}

--[=[
	@within Sodium.Box

	Generates a random X25519 keypair; public key is safe to share, secret key must be kept private.
	The secret key is 32 bytes.
]=]
function Box.Interface.keypair(): Keypair
	local publicKeyPointer = Buffer.alloc(Sys.box.PUBLIC_KEY_BYTES)
	local secretKeyPointer = Buffer.alloc(Sys.box.SECRET_KEY_BYTES)

	local result = Sys.lib.crypto_box_keypair(publicKeyPointer, secretKeyPointer)

	if result ~= 0 then
		Buffer.free(publicKeyPointer)
		Sys.lib.sodium_memzero(secretKeyPointer, Sys.box.SECRET_KEY_BYTES)
		Buffer.free(secretKeyPointer)
		error(`box keypair generation failed (code={result})`)
	end

	local publicKey = Buffer.read(publicKeyPointer, Sys.box.PUBLIC_KEY_BYTES)
	local secretKey = Buffer.read(secretKeyPointer, Sys.box.SECRET_KEY_BYTES)

	Buffer.free(publicKeyPointer)
	Sys.lib.sodium_memzero(secretKeyPointer, Sys.box.SECRET_KEY_BYTES)
	Buffer.free(secretKeyPointer)

	return { publicKey = publicKey, secretKey = secretKey }
end

--[=[
	@within Sodium.Box

	Generates a random 24-byte nonce via libsodium's CSPRNG.
	Generate a fresh nonce for every message - never reuse a nonce with the same keypair.
]=]
function Box.Interface.nonce(): buffer
	local noncePointer = Buffer.alloc(Sys.box.NONCE_BYTES)

	Sys.lib.randombytes_buf(noncePointer, Sys.box.NONCE_BYTES)

	local nonceBytes = Buffer.read(noncePointer, Sys.box.NONCE_BYTES)
	Buffer.free(noncePointer)

	return nonceBytes
end

--[=[
	@within Sodium.Box

	Encrypts `message` from `senderSecretKey` to `recipientPublicKey` using `nonce` (24 bytes).
	Returns a combined buffer: `[mac (16 B)][ciphertext]`.
]=]
function Box.Interface.seal(message: buffer, recipientPublicKey: buffer, senderSecretKey: buffer, nonce: buffer): buffer
	assert(
		buffer.len(recipientPublicKey) == Sys.box.PUBLIC_KEY_BYTES,
		`recipientPublicKey must be {Sys.box.PUBLIC_KEY_BYTES} bytes, got {buffer.len(recipientPublicKey)}`
	)
	assert(
		buffer.len(senderSecretKey) == Sys.box.SECRET_KEY_BYTES,
		`senderSecretKey must be {Sys.box.SECRET_KEY_BYTES} bytes, got {buffer.len(senderSecretKey)}`
	)
	assert(
		buffer.len(nonce) == Sys.box.NONCE_BYTES,
		`nonce must be {Sys.box.NONCE_BYTES} bytes, got {buffer.len(nonce)}`
	)

	local messageLength = buffer.len(message)
	local ciphertextLength = Sys.box.MAC_BYTES + messageLength

	local cipherPointer = Buffer.alloc(ciphertextLength)
	local messagePointer = Buffer.dupe(message)
	local recipientPointer = Buffer.dupe(recipientPublicKey)
	local senderPointer = Buffer.dupe(senderSecretKey)
	local noncePointer = Buffer.dupe(nonce)

	local result = Sys.lib.crypto_box_easy(
		cipherPointer,
		messagePointer,
		messageLength,
		noncePointer,
		recipientPointer,
		senderPointer
	)

	Sys.lib.sodium_memzero(messagePointer, messageLength)
	Buffer.free(messagePointer)
	Buffer.free(recipientPointer)
	Sys.lib.sodium_memzero(senderPointer, Sys.box.SECRET_KEY_BYTES)
	Buffer.free(senderPointer)
	Buffer.free(noncePointer)

	if result ~= 0 then
		Buffer.free(cipherPointer)
		error(`box seal failed (code={result})`)
	end

	local ciphertext = Buffer.read(cipherPointer, ciphertextLength)
	Buffer.free(cipherPointer)

	return ciphertext
end

--[=[
	@within Sodium.Box

	Decrypts a combined `ciphertext` (from `seal`) using `senderPublicKey`, `recipientSecretKey`, and `nonce`.
	Errors if the MAC does not verify.
]=]
function Box.Interface.open(
	ciphertext: buffer,
	senderPublicKey: buffer,
	recipientSecretKey: buffer,
	nonce: buffer
): buffer
	assert(
		buffer.len(senderPublicKey) == Sys.box.PUBLIC_KEY_BYTES,
		`senderPublicKey must be {Sys.box.PUBLIC_KEY_BYTES} bytes, got {buffer.len(senderPublicKey)}`
	)
	assert(
		buffer.len(recipientSecretKey) == Sys.box.SECRET_KEY_BYTES,
		`recipientSecretKey must be {Sys.box.SECRET_KEY_BYTES} bytes, got {buffer.len(recipientSecretKey)}`
	)
	assert(
		buffer.len(nonce) == Sys.box.NONCE_BYTES,
		`nonce must be {Sys.box.NONCE_BYTES} bytes, got {buffer.len(nonce)}`
	)

	local ciphertextLength = buffer.len(ciphertext)

	if ciphertextLength < Sys.box.MAC_BYTES then
		error(`box open: ciphertext too short ({ciphertextLength} bytes, minimum {Sys.box.MAC_BYTES})`)
	end

	local messageLength = ciphertextLength - Sys.box.MAC_BYTES

	local plaintextPointer = Buffer.alloc(messageLength)
	local ciphertextPointer = Buffer.dupe(ciphertext)
	local senderPointer = Buffer.dupe(senderPublicKey)
	local recipientPointer = Buffer.dupe(recipientSecretKey)
	local noncePointer = Buffer.dupe(nonce)

	local result = Sys.lib.crypto_box_open_easy(
		plaintextPointer,
		ciphertextPointer,
		ciphertextLength,
		noncePointer,
		senderPointer,
		recipientPointer
	)

	Buffer.free(ciphertextPointer)
	Buffer.free(senderPointer)
	Sys.lib.sodium_memzero(recipientPointer, Sys.box.SECRET_KEY_BYTES)
	Buffer.free(recipientPointer)
	Buffer.free(noncePointer)

	if result ~= 0 then
		Sys.lib.sodium_memzero(plaintextPointer, messageLength)
		Buffer.free(plaintextPointer)
		error("box open failed: MAC verification failed")
	end

	local plaintext = Buffer.read(plaintextPointer, messageLength)
	Sys.lib.sodium_memzero(plaintextPointer, messageLength)
	Buffer.free(plaintextPointer)

	return plaintext
end

--[=[
	@within Sodium.Box

	Encrypts `message` from `senderSecretKey` to `recipientPublicKey`, returning MAC and ciphertext separately.
	Ciphertext is the same length as the message; MAC and ciphertext are returned as `{ cipher, mac }`.
]=]
function Box.Interface.sealDetached(
	message: buffer,
	recipientPublicKey: buffer,
	senderSecretKey: buffer,
	nonce: buffer
): SealResult
	assert(
		buffer.len(recipientPublicKey) == Sys.box.PUBLIC_KEY_BYTES,
		`recipientPublicKey must be {Sys.box.PUBLIC_KEY_BYTES} bytes, got {buffer.len(recipientPublicKey)}`
	)
	assert(
		buffer.len(senderSecretKey) == Sys.box.SECRET_KEY_BYTES,
		`senderSecretKey must be {Sys.box.SECRET_KEY_BYTES} bytes, got {buffer.len(senderSecretKey)}`
	)
	assert(
		buffer.len(nonce) == Sys.box.NONCE_BYTES,
		`nonce must be {Sys.box.NONCE_BYTES} bytes, got {buffer.len(nonce)}`
	)

	local messageLength = buffer.len(message)

	local cipherPointer = Buffer.alloc(messageLength)
	local macPointer = Buffer.alloc(Sys.box.MAC_BYTES)
	local messagePointer = Buffer.dupe(message)
	local recipientPointer = Buffer.dupe(recipientPublicKey)
	local senderPointer = Buffer.dupe(senderSecretKey)
	local noncePointer = Buffer.dupe(nonce)

	local result = Sys.lib.crypto_box_detached(
		cipherPointer,
		macPointer,
		messagePointer,
		messageLength,
		noncePointer,
		recipientPointer,
		senderPointer
	)

	Sys.lib.sodium_memzero(messagePointer, messageLength)
	Buffer.free(messagePointer)
	Buffer.free(recipientPointer)
	Sys.lib.sodium_memzero(senderPointer, Sys.box.SECRET_KEY_BYTES)
	Buffer.free(senderPointer)
	Buffer.free(noncePointer)

	if result ~= 0 then
		Buffer.free(cipherPointer)
		Buffer.free(macPointer)
		error(`box sealDetached failed (code={result})`)
	end

	local cipher = Buffer.read(cipherPointer, messageLength)
	local mac = Buffer.read(macPointer, Sys.box.MAC_BYTES)

	Buffer.free(cipherPointer)
	Buffer.free(macPointer)

	return { cipher = cipher, mac = mac }
end

--[=[
	@within Sodium.Box

	Decrypts `cipher` using its detached `mac`, `senderPublicKey`, `recipientSecretKey`, and `nonce`.
	Errors if the MAC does not verify.
]=]
function Box.Interface.openDetached(
	cipher: buffer,
	mac: buffer,
	senderPublicKey: buffer,
	recipientSecretKey: buffer,
	nonce: buffer
): buffer
	assert(buffer.len(mac) == Sys.box.MAC_BYTES, `mac must be {Sys.box.MAC_BYTES} bytes, got {buffer.len(mac)}`)
	assert(
		buffer.len(senderPublicKey) == Sys.box.PUBLIC_KEY_BYTES,
		`senderPublicKey must be {Sys.box.PUBLIC_KEY_BYTES} bytes, got {buffer.len(senderPublicKey)}`
	)
	assert(
		buffer.len(recipientSecretKey) == Sys.box.SECRET_KEY_BYTES,
		`recipientSecretKey must be {Sys.box.SECRET_KEY_BYTES} bytes, got {buffer.len(recipientSecretKey)}`
	)
	assert(
		buffer.len(nonce) == Sys.box.NONCE_BYTES,
		`nonce must be {Sys.box.NONCE_BYTES} bytes, got {buffer.len(nonce)}`
	)

	local messageLength = buffer.len(cipher)

	local plaintextPointer = Buffer.alloc(messageLength)
	local cipherPointer = Buffer.dupe(cipher)
	local macPointer = Buffer.dupe(mac)
	local senderPointer = Buffer.dupe(senderPublicKey)
	local recipientPointer = Buffer.dupe(recipientSecretKey)
	local noncePointer = Buffer.dupe(nonce)

	local result = Sys.lib.crypto_box_open_detached(
		plaintextPointer,
		cipherPointer,
		macPointer,
		messageLength,
		noncePointer,
		senderPointer,
		recipientPointer
	)

	Buffer.free(cipherPointer)
	Buffer.free(macPointer)
	Buffer.free(senderPointer)
	Sys.lib.sodium_memzero(recipientPointer, Sys.box.SECRET_KEY_BYTES)
	Buffer.free(recipientPointer)
	Buffer.free(noncePointer)

	if result ~= 0 then
		Sys.lib.sodium_memzero(plaintextPointer, messageLength)
		Buffer.free(plaintextPointer)
		error("box openDetached failed: MAC verification failed")
	end

	local plaintext = Buffer.read(plaintextPointer, messageLength)
	Sys.lib.sodium_memzero(plaintextPointer, messageLength)
	Buffer.free(plaintextPointer)

	return plaintext
end

--[=[
	@within Sodium.Box

	Computes a 32-byte shared key from `recipientPublicKey` and `senderSecretKey` via X25519 Diffie-Hellman.
	Pass the result to `sealAfterPrecompute`/`openAfterPrecompute` to avoid repeating the DH per message.
]=]
function Box.Interface.precompute(recipientPublicKey: buffer, senderSecretKey: buffer): buffer
	assert(
		buffer.len(recipientPublicKey) == Sys.box.PUBLIC_KEY_BYTES,
		`recipientPublicKey must be {Sys.box.PUBLIC_KEY_BYTES} bytes, got {buffer.len(recipientPublicKey)}`
	)
	assert(
		buffer.len(senderSecretKey) == Sys.box.SECRET_KEY_BYTES,
		`senderSecretKey must be {Sys.box.SECRET_KEY_BYTES} bytes, got {buffer.len(senderSecretKey)}`
	)

	local sharedKeyPointer = Buffer.alloc(Sys.box.BEFORENM_BYTES)
	local recipientPointer = Buffer.dupe(recipientPublicKey)
	local senderPointer = Buffer.dupe(senderSecretKey)

	local result = Sys.lib.crypto_box_beforenm(sharedKeyPointer, recipientPointer, senderPointer)

	Buffer.free(recipientPointer)
	Sys.lib.sodium_memzero(senderPointer, Sys.box.SECRET_KEY_BYTES)
	Buffer.free(senderPointer)

	if result ~= 0 then
		Buffer.free(sharedKeyPointer)
		error(`box precompute failed (code={result})`)
	end

	local sharedKey = Buffer.read(sharedKeyPointer, Sys.box.BEFORENM_BYTES)
	Sys.lib.sodium_memzero(sharedKeyPointer, Sys.box.BEFORENM_BYTES)
	Buffer.free(sharedKeyPointer)

	return sharedKey
end

--[=[
	@within Sodium.Box

	Encrypts `message` using a precomputed `sharedKey` (from `precompute`) and `nonce`.
	Returns a combined buffer: `[mac (16 B)][ciphertext]`.
]=]
function Box.Interface.sealAfterPrecompute(message: buffer, sharedKey: buffer, nonce: buffer): buffer
	assert(
		buffer.len(sharedKey) == Sys.box.BEFORENM_BYTES,
		`sharedKey must be {Sys.box.BEFORENM_BYTES} bytes, got {buffer.len(sharedKey)}`
	)
	assert(
		buffer.len(nonce) == Sys.box.NONCE_BYTES,
		`nonce must be {Sys.box.NONCE_BYTES} bytes, got {buffer.len(nonce)}`
	)

	local messageLength = buffer.len(message)
	local ciphertextLength = Sys.box.MAC_BYTES + messageLength

	local cipherPointer = Buffer.alloc(ciphertextLength)
	local messagePointer = Buffer.dupe(message)
	local sharedKeyPointer = Buffer.dupe(sharedKey)
	local noncePointer = Buffer.dupe(nonce)

	local result =
		Sys.lib.crypto_box_easy_afternm(cipherPointer, messagePointer, messageLength, noncePointer, sharedKeyPointer)

	Sys.lib.sodium_memzero(messagePointer, messageLength)
	Buffer.free(messagePointer)
	Sys.lib.sodium_memzero(sharedKeyPointer, Sys.box.BEFORENM_BYTES)
	Buffer.free(sharedKeyPointer)
	Buffer.free(noncePointer)

	if result ~= 0 then
		Buffer.free(cipherPointer)
		error(`box sealAfterPrecompute failed (code={result})`)
	end

	local ciphertext = Buffer.read(cipherPointer, ciphertextLength)
	Buffer.free(cipherPointer)

	return ciphertext
end

--[=[
	@within Sodium.Box

	Decrypts a combined `ciphertext` (from `sealAfterPrecompute`) using a precomputed `sharedKey` and `nonce`.
	Errors if the MAC does not verify.
]=]
function Box.Interface.openAfterPrecompute(ciphertext: buffer, sharedKey: buffer, nonce: buffer): buffer
	assert(
		buffer.len(sharedKey) == Sys.box.BEFORENM_BYTES,
		`sharedKey must be {Sys.box.BEFORENM_BYTES} bytes, got {buffer.len(sharedKey)}`
	)
	assert(
		buffer.len(nonce) == Sys.box.NONCE_BYTES,
		`nonce must be {Sys.box.NONCE_BYTES} bytes, got {buffer.len(nonce)}`
	)

	local ciphertextLength = buffer.len(ciphertext)

	if ciphertextLength < Sys.box.MAC_BYTES then
		error(`box openAfterPrecompute: ciphertext too short ({ciphertextLength} bytes, minimum {Sys.box.MAC_BYTES})`)
	end

	local messageLength = ciphertextLength - Sys.box.MAC_BYTES

	local plaintextPointer = Buffer.alloc(messageLength)
	local ciphertextPointer = Buffer.dupe(ciphertext)
	local sharedKeyPointer = Buffer.dupe(sharedKey)
	local noncePointer = Buffer.dupe(nonce)

	local result = Sys.lib.crypto_box_open_easy_afternm(
		plaintextPointer,
		ciphertextPointer,
		ciphertextLength,
		noncePointer,
		sharedKeyPointer
	)

	Buffer.free(ciphertextPointer)
	Sys.lib.sodium_memzero(sharedKeyPointer, Sys.box.BEFORENM_BYTES)
	Buffer.free(sharedKeyPointer)
	Buffer.free(noncePointer)

	if result ~= 0 then
		Sys.lib.sodium_memzero(plaintextPointer, messageLength)
		Buffer.free(plaintextPointer)
		error("box openAfterPrecompute failed: MAC verification failed")
	end

	local plaintext = Buffer.read(plaintextPointer, messageLength)
	Sys.lib.sodium_memzero(plaintextPointer, messageLength)
	Buffer.free(plaintextPointer)

	return plaintext
end

return Box.Interface
