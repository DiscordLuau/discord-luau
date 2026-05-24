--[=[
	@class Sodium.Sign

	Ed25519 digital signatures using the detached form - the signature is separate from the message.
	Signs with a 64-byte secret key; verifies with the corresponding 32-byte public key.
	`verify` returns a boolean rather than erroring, so callers can branch without a `pcall` wrapper.
]=]

local Sys = require("./sys")
local Buffer = require("./buffer")

export type Keypair = Buffer.Keypair

local Sign = {}

Sign.Interface = {}

--[=[
	@within Sodium.Sign

	Generates a random Ed25519 keypair; public key is safe to share, secret key must be kept private.
	The secret key is 64 bytes (seed + public key); call `secretKeyToPublicKey` to recover the public key from it.
]=]
function Sign.Interface.keypair(): Keypair
	local publicKeyPointer = Buffer.alloc(Sys.sign.PUBLIC_KEY_BYTES)
	local secretKeyPointer = Buffer.alloc(Sys.sign.SECRET_KEY_BYTES)

	local result = Sys.lib.crypto_sign_keypair(publicKeyPointer, secretKeyPointer)

	if result ~= 0 then
		Buffer.free(publicKeyPointer)
		Sys.lib.sodium_memzero(secretKeyPointer, Sys.sign.SECRET_KEY_BYTES)
		Buffer.free(secretKeyPointer)
		error(`sign keypair generation failed (code={result})`)
	end

	local publicKey = Buffer.read(publicKeyPointer, Sys.sign.PUBLIC_KEY_BYTES)
	local secretKey = Buffer.read(secretKeyPointer, Sys.sign.SECRET_KEY_BYTES)

	Buffer.free(publicKeyPointer)
	Sys.lib.sodium_memzero(secretKeyPointer, Sys.sign.SECRET_KEY_BYTES)
	Buffer.free(secretKeyPointer)

	return { publicKey = publicKey, secretKey = secretKey }
end

--[=[
	@within Sodium.Sign

	Derives the 32-byte public key from a 64-byte Ed25519 `secretKey`.
	Useful when only the secret key was persisted and the public key needs to be recovered.
]=]
function Sign.Interface.secretKeyToPublicKey(secretKey: buffer): buffer
	assert(
		buffer.len(secretKey) == Sys.sign.SECRET_KEY_BYTES,
		`secretKey must be {Sys.sign.SECRET_KEY_BYTES} bytes, got {buffer.len(secretKey)}`
	)

	local publicKeyPointer = Buffer.alloc(Sys.sign.PUBLIC_KEY_BYTES)
	local secretKeyPointer = Buffer.dupe(secretKey)

	local result = Sys.lib.crypto_sign_ed25519_sk_to_pk(publicKeyPointer, secretKeyPointer)

	Sys.lib.sodium_memzero(secretKeyPointer, Sys.sign.SECRET_KEY_BYTES)
	Buffer.free(secretKeyPointer)

	if result ~= 0 then
		Buffer.free(publicKeyPointer)
		error(`sign secretKeyToPublicKey failed (code={result})`)
	end

	local publicKey = Buffer.read(publicKeyPointer, Sys.sign.PUBLIC_KEY_BYTES)
	Buffer.free(publicKeyPointer)

	return publicKey
end

--[=[
	@within Sodium.Sign

	Signs `message` with `secretKey` (64 bytes) and returns the 64-byte detached signature.
	The message itself is not modified or included in the return value.
]=]
function Sign.Interface.sign(message: buffer, secretKey: buffer): buffer
	assert(
		buffer.len(secretKey) == Sys.sign.SECRET_KEY_BYTES,
		`secretKey must be {Sys.sign.SECRET_KEY_BYTES} bytes, got {buffer.len(secretKey)}`
	)

	local messageLength = buffer.len(message)

	local signaturePointer = Buffer.alloc(Sys.sign.BYTES)
	local messagePointer = Buffer.dupe(message)
	local secretKeyPointer = Buffer.dupe(secretKey)
	local nullPointer = Buffer.getNull()

	-- siglenP is passed as null - Ed25519 signatures are always exactly BYTES long
	local result =
		Sys.lib.crypto_sign_detached(signaturePointer, nullPointer, messagePointer, messageLength, secretKeyPointer)

	Buffer.free(messagePointer)
	Sys.lib.sodium_memzero(secretKeyPointer, Sys.sign.SECRET_KEY_BYTES)
	Buffer.free(secretKeyPointer)

	if result ~= 0 then
		Buffer.free(signaturePointer)
		error(`sign failed (code={result})`)
	end

	local signature = Buffer.read(signaturePointer, Sys.sign.BYTES)
	Buffer.free(signaturePointer)

	return signature
end

--[=[
	@within Sodium.Sign

	Verifies `signature` (64 bytes) against `message` under `publicKey` (32 bytes).
	Returns `true` if valid, `false` otherwise - does not error on invalid signatures.
]=]
function Sign.Interface.verify(signature: buffer, message: buffer, publicKey: buffer): boolean
	assert(
		buffer.len(signature) == Sys.sign.BYTES,
		`signature must be {Sys.sign.BYTES} bytes, got {buffer.len(signature)}`
	)
	assert(
		buffer.len(publicKey) == Sys.sign.PUBLIC_KEY_BYTES,
		`publicKey must be {Sys.sign.PUBLIC_KEY_BYTES} bytes, got {buffer.len(publicKey)}`
	)

	local messageLength = buffer.len(message)

	local signaturePointer = Buffer.dupe(signature)
	local messagePointer = Buffer.dupe(message)
	local publicKeyPointer = Buffer.dupe(publicKey)

	local result =
		Sys.lib.crypto_sign_verify_detached(signaturePointer, messagePointer, messageLength, publicKeyPointer)

	Buffer.free(signaturePointer)
	Buffer.free(messagePointer)
	Buffer.free(publicKeyPointer)

	return result == 0
end

return Sign.Interface
