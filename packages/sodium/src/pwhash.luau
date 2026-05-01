--[=[
	@class Sodium.Pwhash

	Argon2id password hashing and key derivation from passwords - all operations are intentionally slow.
	Key derivation (`hash`): derives a fixed-length symmetric key from a password and a random salt.
	Password storage (`hashStr`/`verifyStr`): produces a self-contained encoded string with embedded salt.
	Use `INTERACTIVE` presets for login flows and `SENSITIVE` for long-lived key derivation.
]=]

local Sys = require("./sys")
local Buffer = require("./buffer")

local function dupePassword(password: buffer): (FFIPointer, number)
	return Buffer.dupe(password), buffer.len(password)
end

local function makeHashStringBuffer(hashString: string): FFIPointer
	if #hashString >= Sys.pwhash.STR_BYTES then
		error(`pwhash: hash string too long ({#hashString} bytes, max {Sys.pwhash.STR_BYTES - 1})`)
	end

	local buf = buffer.create(Sys.pwhash.STR_BYTES)
	buffer.writestring(buf, 0, hashString)
	return Buffer.dupe(buf)
end

local Pwhash = {}

Pwhash.Interface = {}

--[=[
	@within Sodium.Pwhash

	Derives a key of `outputBytes` bytes from `password` and a 16-byte `salt` using Argon2id.
	`opsLimit` and `memLimit` default to the interactive presets; increase to moderate or sensitive for stronger derivation.
]=]
function Pwhash.Interface.hash(password: buffer, salt: buffer, outputBytes: number, opsLimit: number?, memLimit: number?): buffer
	assert(
		outputBytes >= Sys.pwhash.BYTES_MIN and outputBytes <= Sys.pwhash.BYTES_MAX,
		`outputBytes must be {Sys.pwhash.BYTES_MIN}–{Sys.pwhash.BYTES_MAX}, got {outputBytes}`
	)
	assert(buffer.len(salt) == Sys.pwhash.SALT_BYTES, `salt must be {Sys.pwhash.SALT_BYTES} bytes, got {buffer.len(salt)}`)

	local operationsLimit = opsLimit or Sys.pwhash.OPSLIMIT_INTERACTIVE
	local memoryLimit = memLimit or Sys.pwhash.MEMLIMIT_INTERACTIVE
	local outputPointer = Buffer.alloc(outputBytes)
	local saltPointer = Buffer.dupe(salt)
	local passwordPointer, passwordLength = dupePassword(password)

	local result = Sys.lib.crypto_pwhash(
		outputPointer,
		outputBytes,
		passwordPointer,
		passwordLength,
		saltPointer,
		operationsLimit,
		memoryLimit,
		Sys.pwhash.ALG_ARGON2ID13
	)

	Sys.lib.sodium_memzero(passwordPointer, passwordLength)
	Buffer.free(passwordPointer)
	Buffer.free(saltPointer)

	if result ~= 0 then
		Sys.lib.sodium_memzero(outputPointer, outputBytes)
		Buffer.free(outputPointer)
		error("pwhash failed: out of memory or invalid parameters")
	end

	local key = Buffer.read(outputPointer, outputBytes)
	Sys.lib.sodium_memzero(outputPointer, outputBytes)
	Buffer.free(outputPointer)

	return key
end

--[=[
	@within Sodium.Pwhash

	Hashes `password` for storage, returning a self-contained encoded string with embedded salt and parameters.
	`opsLimit` and `memLimit` default to the interactive presets; errors if hashing fails.
]=]
function Pwhash.Interface.hashStr(password: buffer, opsLimit: number?, memLimit: number?): string
	local operationsLimit = opsLimit or Sys.pwhash.OPSLIMIT_INTERACTIVE
	local memoryLimit = memLimit or Sys.pwhash.MEMLIMIT_INTERACTIVE
	local outputPointer = Buffer.alloc(Sys.pwhash.STR_BYTES)
	local passwordPointer, passwordLength = dupePassword(password)

	local result =
		Sys.lib.crypto_pwhash_str(outputPointer, passwordPointer, passwordLength, operationsLimit, memoryLimit)

	Sys.lib.sodium_memzero(passwordPointer, passwordLength)
	Buffer.free(passwordPointer)

	if result ~= 0 then
		Sys.lib.sodium_memzero(outputPointer, Sys.pwhash.STR_BYTES)
		Buffer.free(outputPointer)
		error("pwhash hashStr failed: out of memory or invalid parameters")
	end

	local encoded = Buffer.fromCString(outputPointer, Sys.pwhash.STR_BYTES)

	Sys.lib.sodium_memzero(outputPointer, Sys.pwhash.STR_BYTES)
	Buffer.free(outputPointer)

	return encoded
end

--[=[
	@within Sodium.Pwhash

	Verifies that `password` matches the encoded hash produced by `hashStr`.
	Returns `true` if the password is correct, `false` otherwise - does not error on wrong passwords.
]=]
function Pwhash.Interface.verifyStr(hashString: string, password: buffer): boolean
	local hashStringPointer = makeHashStringBuffer(hashString)
	local passwordPointer, passwordLength = dupePassword(password)

	local result = Sys.lib.crypto_pwhash_str_verify(hashStringPointer, passwordPointer, passwordLength)

	Sys.lib.sodium_memzero(hashStringPointer, Sys.pwhash.STR_BYTES)
	Buffer.free(hashStringPointer)
	Sys.lib.sodium_memzero(passwordPointer, passwordLength)
	Buffer.free(passwordPointer)

	return result == 0
end

--[=[
	@within Sodium.Pwhash

	Returns `true` if the stored hash was produced with parameters weaker than `opsLimit`/`memLimit`.
	Use after a successful `verifyStr` to decide whether to upgrade the stored hash; errors if `hashStr` is invalid.
]=]
function Pwhash.Interface.needsRehash(hashString: string, opsLimit: number?, memLimit: number?): boolean
	local operationsLimit = opsLimit or Sys.pwhash.OPSLIMIT_INTERACTIVE
	local memoryLimit = memLimit or Sys.pwhash.MEMLIMIT_INTERACTIVE
	local hashStringPointer = makeHashStringBuffer(hashString)

	local result = Sys.lib.crypto_pwhash_str_needs_rehash(hashStringPointer, operationsLimit, memoryLimit)

	Sys.lib.sodium_memzero(hashStringPointer, Sys.pwhash.STR_BYTES)
	Buffer.free(hashStringPointer)

	if result == -1 then
		error("pwhash needsRehash: invalid hash string")
	end

	return result == 1
end

return Pwhash.Interface
