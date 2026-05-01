--[=[
	@class Sodium.Randombytes

	Cryptographically secure random byte generation backed by the OS CSPRNG.
	Exposes libsodium's `randombytes_buf` for cases where raw random bytes are needed directly.
]=]

local Sys = require("./sys")
local Buffer = require("./buffer")

local Randombytes = {}

Randombytes.Interface = {}

--[=[
	@within Sodium.Randombytes

	Returns a buffer of `size` random bytes from the OS CSPRNG.
]=]
function Randombytes.Interface.buf(size: number): buffer
	local pointer = Buffer.alloc(size)

	Sys.lib.randombytes_buf(pointer, size)

	local result = Buffer.read(pointer, size)

	Buffer.free(pointer)

	return result
end

--[=[
	@within Sodium.Randombytes

	Returns a uniformly distributed random number in `[0, upperBound)` without modulo bias.
	`upperBound` must be greater than 0.
]=]
function Randombytes.Interface.uniform(upperBound: number): number
	assert(upperBound > 0, `randombytes.uniform: upperBound must be > 0, got {upperBound}`)
	return Sys.lib.randombytes_uniform(upperBound)
end

return Randombytes.Interface
