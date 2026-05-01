--[=[
	@class Sodium.Hash

	SHA-256 and SHA-512 one-shot hash functions.
	For a keyed hash or variable-length output, prefer `generichash`; for password hashing, use `pwhash`.
]=]

local Sys = require("./sys")
local Buffer = require("./buffer")

local Hash = {}

Hash.Interface = {}

--[=[
	@within Sodium.Hash

	Returns the SHA-256 digest of `message` as a 32-byte buffer.
]=]
function Hash.Interface.sha256(message: buffer): buffer
	local messageLength = buffer.len(message)
	local outputPointer = Buffer.alloc(Sys.hash.SHA256_BYTES)
	local inputPointer = Buffer.dupe(message)

	local result = Sys.lib.crypto_hash_sha256(outputPointer, inputPointer, messageLength)

	Buffer.free(inputPointer)

	if result ~= 0 then
		Buffer.free(outputPointer)
		error(`sha256 failed (code={result})`)
	end

	local digest = Buffer.read(outputPointer, Sys.hash.SHA256_BYTES)

	Buffer.free(outputPointer)

	return digest
end

--[=[
	@within Sodium.Hash

	Returns the SHA-512 digest of `message` as a 64-byte buffer.
]=]
function Hash.Interface.sha512(message: buffer): buffer
	local messageLength = buffer.len(message)
	local outputPointer = Buffer.alloc(Sys.hash.SHA512_BYTES)
	local inputPointer = Buffer.dupe(message)

	local result = Sys.lib.crypto_hash_sha512(outputPointer, inputPointer, messageLength)

	Buffer.free(inputPointer)

	if result ~= 0 then
		Buffer.free(outputPointer)
		error(`sha512 failed (code={result})`)
	end

	local digest = Buffer.read(outputPointer, Sys.hash.SHA512_BYTES)

	Buffer.free(outputPointer)

	return digest
end

return Hash.Interface
