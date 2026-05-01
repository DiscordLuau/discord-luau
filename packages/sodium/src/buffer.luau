--[=[
	@class Sodium.Buffer
	@private

	Internal FFI interoperability helpers for the Sodium package.
	Wraps `stdPolyfills.ffi` into named operations so higher-level modules never interact with it directly.
]=]

local stdPolyfills = require("../luau_packages/std_polyfills")

local ffi = stdPolyfills.ffi

--[=[
	@type EncryptResult { cipher: buffer, tag: buffer }
	@within Sodium.Buffer

	Return value from AEAD encrypt calls; cipher matches plaintext length, tag is 16 bytes.
]=]
export type EncryptResult = { cipher: buffer, tag: buffer }

--[=[
	@type SealResult { cipher: buffer, mac: buffer }
	@within Sodium.Buffer

	Return value from secretbox and box sealDetached calls; cipher matches plaintext length, mac is 16 bytes.
]=]
export type SealResult = { cipher: buffer, mac: buffer }

--[=[
	@type Keypair { publicKey: buffer, secretKey: buffer }
	@within Sodium.Buffer

	Return value from `box.keypair` and `sign.keypair`.
]=]
export type Keypair = { publicKey: buffer, secretKey: buffer }

--[=[
	@type Aead<T> table
	@within Sodium.Buffer

	Generic interface satisfied by all three AEAD modules.
	T is an intersection of algorithm-specific extras, e.g. aes256gcm extends with isAvailable.
]=]
export type Aead<T> = {
	KEY_BYTES: number,
	NONCE_BYTES: number,
	TAG_BYTES: number,
	keygen: () -> buffer,
	encrypt: (plaintext: buffer, key: buffer, nonce: buffer, ad: buffer?) -> EncryptResult,
	decrypt: (cipher: buffer, tag: buffer, key: buffer, nonce: buffer, ad: buffer?) -> buffer,
} & T

local SodiumBuffer = {}

SodiumBuffer.Interface = {}

--[=[
	@within Sodium.Buffer
]=]
function SodiumBuffer.Interface.alloc(size: number): FFIPointer
	return ffi.alloc(size, 1)
end

--[=[
	@within Sodium.Buffer
]=]
function SodiumBuffer.Interface.dupe(buf: buffer): FFIPointer
	return ffi.dupe(buf)
end

--[=[
	@within Sodium.Buffer
]=]
function SodiumBuffer.Interface.free(pointer: FFIPointer)
	ffi.free(pointer)
end

--[=[
	@within Sodium.Buffer

	Reads `length` bytes from `pointer` into a freshly created Luau buffer.
]=]
function SodiumBuffer.Interface.read(pointer: FFIPointer, length: number): buffer
	local result = buffer.create(length)
	pointer:read(0, result, 0, length)
	return result
end

--[=[
	@within Sodium.Buffer

	Returns a null FFI pointer for optional pointer arguments.
]=]
function SodiumBuffer.Interface.getNull(): FFIPointer
	return ffi.getNull()
end

--[=[
	@within Sodium.Buffer

	Allocates an 8-byte, 8-aligned slot for `size_t *` output parameters.
]=]
function SodiumBuffer.Interface.allocSlot(): FFIPointer
	return ffi.alloc(8, 8)
end

--[=[
	@within Sodium.Buffer

	Reads a `u64` return that may come back as a plain Luau `number` or a two-word `buffer`.
]=]
function SodiumBuffer.Interface.readRawU64(value: any): number
	if type(value) == "number" then
		return value
	end

	local raw = value :: buffer
	local low = buffer.readu32(raw, 0)
	local high = buffer.readu32(raw, 4)

	return high * 4294967296 + low
end

--[=[
	@within Sodium.Buffer

	Reads a `size_t` value written into an 8-byte slot by a libsodium function.
]=]
function SodiumBuffer.Interface.readSizeT(slot: FFIPointer): number
	return SodiumBuffer.Interface.readRawU64(slot:readu64(0))
end

--[=[
	@within Sodium.Buffer

	Copies `s` into a null-terminated C string in FFI memory; caller must free the result.
]=]
function SodiumBuffer.Interface.toCString(s: string): FFIPointer
	local length = #s
	local buf = buffer.create(length + 1)
	buffer.writestring(buf, 0, s)
	buffer.writeu8(buf, length, 0)
	return ffi.dupe(buf)
end

--[=[
	@within Sodium.Buffer

	Reads a null-terminated C string from an FFI pointer into a Luau string, up to `maxLength` bytes.
]=]
function SodiumBuffer.Interface.fromCString(pointer: FFIPointer, maxLength: number): string
	local chars = table.create(32)
	local offset = 0

	while offset < maxLength do
		local byte = pointer:readu8(offset)

		if byte == 0 then
			break
		end

		chars[#chars + 1] = string.char(byte)
		offset += 1
	end

	return table.concat(chars)
end

return SodiumBuffer.Interface
