--[=[
	@class Sodium.Utils

	Utility helpers: constant-time comparison, memory zeroing, and hex/base64 encode/decode.
	All encoding and decoding goes through libsodium, ensuring compatibility with other libsodium consumers.
]=]

local Sys = require("./sys")
local Buffer = require("./buffer")

local Utils = {}

Utils.Interface = {}

--[=[
	@within Sodium.Utils

	Compares `a` and `b` in constant time; returns `true` if they are equal.
	Both buffers must be the same length - use this for all secret-value comparisons to prevent timing attacks.
]=]
function Utils.Interface.memcmp(a: buffer, b: buffer): boolean
	local aLength = buffer.len(a)
	local bLength = buffer.len(b)

	if aLength ~= bLength then
		error(`utils.memcmp: buffers have different lengths ({aLength} vs {bLength})`)
	end

	local aPointer = Buffer.dupe(a)
	local bPointer = Buffer.dupe(b)

	local result = Sys.lib.sodium_memcmp(aPointer, bPointer, aLength)

	Sys.lib.sodium_memzero(aPointer, aLength)
	Buffer.free(aPointer)
	Sys.lib.sodium_memzero(bPointer, bLength)
	Buffer.free(bPointer)

	return result == 0
end

--[=[
	@within Sodium.Utils

	Zeroes `length` bytes at `pointer` in a way the compiler cannot optimise away.
	Operates on FFI-allocated memory only; for Luau buffers use `buffer.fill` instead.
]=]
function Utils.Interface.memzero(pointer: FFIPointer, length: number)
	Sys.lib.sodium_memzero(pointer, length)
end

--[=[
	@within Sodium.Utils

	Encodes `data` as a lowercase hex string via libsodium.
	Output length is always `2 * buffer.len(data)` characters.
]=]
function Utils.Interface.bin2hex(data: buffer): string
	local binaryLength = buffer.len(data)
	local hexMaxLength = binaryLength * 2 + 1
	local hexPointer = Buffer.alloc(hexMaxLength)
	local binaryPointer = Buffer.dupe(data)

	Sys.lib.sodium_bin2hex(hexPointer, hexMaxLength, binaryPointer, binaryLength)

	Buffer.free(binaryPointer)

	local hex = Buffer.fromCString(hexPointer, hexMaxLength)

	Buffer.free(hexPointer)

	return hex
end

--[=[
	@within Sodium.Utils

	Decodes a hex string into a binary buffer; accepts both upper and lower case.
	Errors if `hex` contains characters outside `[0-9a-fA-F]`.
]=]
function Utils.Interface.hex2bin(hex: string): buffer
	local hexLength = #hex
	local binaryMaxLength = hexLength // 2
	local binaryPointer = Buffer.alloc(binaryMaxLength)
	local hexPointer = Buffer.toCString(hex)
	local binaryLengthSlot = Buffer.allocSlot()
	local nullPointer = Buffer.getNull()

	local result = Sys.lib.sodium_hex2bin(
		binaryPointer,
		binaryMaxLength,
		hexPointer,
		hexLength,
		nullPointer,
		binaryLengthSlot,
		nullPointer
	)

	Buffer.free(hexPointer)

	if result ~= 0 then
		Buffer.free(binaryPointer)
		Buffer.free(binaryLengthSlot)
		error("utils.hex2bin: invalid hex string")
	end

	local binaryLength = Buffer.readSizeT(binaryLengthSlot)

	Buffer.free(binaryLengthSlot)

	local decoded = Buffer.read(binaryPointer, binaryLength)

	Buffer.free(binaryPointer)

	return decoded
end

--[=[
	@within Sodium.Utils

	Encodes `data` as a base64 string; `variant` selects the alphabet and padding.
	Variants: `Sys.base64.VARIANT_ORIGINAL` (default), `Sys.base64.VARIANT_ORIGINAL_NO_PADDING`, `BASE64_URLSAFE`, `BASE64_URLSAFE_NO_PADDING`.
]=]
function Utils.Interface.bin2base64(data: buffer, variant: number?): string
	local variantId = variant or Sys.base64.VARIANT_ORIGINAL
	local binaryLength = buffer.len(data)
	local base64MaxLength = Buffer.readRawU64(Sys.lib.sodium_base64_encoded_len(binaryLength, variantId))
	local base64Pointer = Buffer.alloc(base64MaxLength)
	local binaryPointer = Buffer.dupe(data)

	Sys.lib.sodium_bin2base64(base64Pointer, base64MaxLength, binaryPointer, binaryLength, variantId)

	Buffer.free(binaryPointer)

	local base64 = Buffer.fromCString(base64Pointer, base64MaxLength)

	Buffer.free(base64Pointer)

	return base64
end

--[=[
	@within Sodium.Utils

	Decodes a base64 string into a binary buffer; `variant` must match the one used during encoding.
	Whitespace is not ignored - strip it beforehand. Errors on invalid input.
]=]
function Utils.Interface.base642bin(base64: string, variant: number?): buffer
	local variantId = variant or Sys.base64.VARIANT_ORIGINAL
	local base64Length = #base64
	local binaryMaxLength = (base64Length * 3) // 4 + 1
	local binaryPointer = Buffer.alloc(binaryMaxLength)
	local base64Pointer = Buffer.toCString(base64)
	local binaryLengthSlot = Buffer.allocSlot()
	local nullPointer = Buffer.getNull()

	local result = Sys.lib.sodium_base642bin(
		binaryPointer,
		binaryMaxLength,
		base64Pointer,
		base64Length,
		nullPointer,
		binaryLengthSlot,
		nullPointer,
		variantId
	)

	Buffer.free(base64Pointer)

	if result ~= 0 then
		Buffer.free(binaryPointer)
		Buffer.free(binaryLengthSlot)
		error("utils.base642bin: invalid base64 input")
	end

	local binaryLength = Buffer.readSizeT(binaryLengthSlot)

	Buffer.free(binaryLengthSlot)

	local decoded = Buffer.read(binaryPointer, binaryLength)

	Buffer.free(binaryPointer)

	return decoded
end

return Utils.Interface
