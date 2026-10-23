--[=[
	@class Dave.Decryptor
	@__index Prototype

	Decrypts incoming media frames using the DAVE protocol.

	A Decryptor is created per remote participant stream. When the MLS group transitions
	to a new epoch, call `transitionToKeyRatchet` with the ratchet derived for that
	participant; the decryptor will maintain both the old and new ratchets for a short
	overlap window to absorb in-flight frames. Before the group is ready, call
	`transitionToPassthroughMode(true)` so frames pass through without attempting
	decryption.

	```lua
	local dec = Dave.Decryptor.new()
	
	dec:transitionToKeyRatchet(session:getKeyRatchet(remoteUserId))

	local plaintext = dec:decrypt(Dave.sys.mediaType.audio, encryptedFrame)
	```
]=]

--[=[
	@prop handle Sys.DecryptorHandle?
	@within Dave.Decryptor
]=]

local stdPolyfills = require("../luau_packages/std_polyfills")
local Sys = require("./sys")
local Buffer = require("./buffer")
local KeyRatchet = require("./keyRatchet")

local decryptorResultMessages = {
	[Sys.decryptorResultCode.decryptionFailure] = "decryption failure",
	[Sys.decryptorResultCode.missingKeyRatchet] = "missing key ratchet",
	[Sys.decryptorResultCode.invalidNonce] = "invalid nonce",
	[Sys.decryptorResultCode.missingCryptor] = "missing cryptor",
}

local Decryptor = {}

Decryptor.Interface = {}
Decryptor.Prototype = {}

--[=[
	@within Dave.Decryptor

	Transitions the decryptor to use a new key ratchet, typically called after each MLS
	epoch change. The library retains both the old and new ratchets for a short overlap
	window so in-flight frames encrypted under the previous epoch are still accepted.
	Obtain a ratchet from `Session:getKeyRatchet(remoteUserId)`.
]=]
function Decryptor.Prototype.transitionToKeyRatchet(self: Decryptor, keyRatchet: KeyRatchet.KeyRatchet)
	local handle = assert(self.handle, "Decryptor has been destroyed")

	Sys.lib.daveDecryptorTransitionToKeyRatchet(handle, keyRatchet.handle)
end

--[=[
	@within Dave.Decryptor

	Transitions the decryptor into or out of passthrough mode. When enabled, frames are
	returned from `decrypt` unchanged without any key material being consumed. Use this
	while the MLS group is not yet established.
]=]
function Decryptor.Prototype.transitionToPassthroughMode(self: Decryptor, enabled: boolean)
	local handle = assert(self.handle, "Decryptor has been destroyed")

	Sys.lib.daveDecryptorTransitionToPassthroughMode(handle, if enabled then 1 else 0)
end

--[=[
	@within Dave.Decryptor

	Returns the maximum number of plaintext bytes that `decrypt` may produce for an
	encrypted frame of `encryptedFrameSize` bytes on `mediaType`. Useful for
	pre-allocating receive buffers.
]=]
function Decryptor.Prototype.getMaxPlaintextByteSize(
	self: Decryptor,
	mediaType: number,
	encryptedFrameSize: number
): number
	local handle = assert(self.handle, "Decryptor has been destroyed")

	return Buffer.readRawU64(Sys.lib.daveDecryptorGetMaxPlaintextByteSize(handle, mediaType, encryptedFrameSize))
end

--[=[
	@within Dave.Decryptor

	Decrypts `encryptedFrame` and returns the plaintext as a new buffer. Raises an error
	naming the result code on any non-success result (missing ratchet, invalid nonce,
	etc.), so a caller that expects failures during key transitions can `pcall` it.
]=]
function Decryptor.Prototype.decrypt(self: Decryptor, mediaType: number, encryptedFrame: buffer): buffer
	local handle = assert(self.handle, "Decryptor has been destroyed")
	local encryptedFrameSize = buffer.len(encryptedFrame)
	local maxOutputSize = self:getMaxPlaintextByteSize(mediaType, encryptedFrameSize)
	local outputPointer = stdPolyfills.ffi.alloc(maxOutputSize, 1)
	local encryptedFramePointer = stdPolyfills.ffi.dupe(encryptedFrame)
	local bytesWrittenSlot = Buffer.allocateSlot()
	local resultCode = Sys.lib.daveDecryptorDecrypt(
		handle,
		mediaType,
		encryptedFramePointer,
		encryptedFrameSize,
		outputPointer,
		maxOutputSize,
		bytesWrittenSlot
	)

	stdPolyfills.ffi.free(encryptedFramePointer)

	if resultCode ~= Sys.decryptorResultCode.success then
		stdPolyfills.ffi.free(outputPointer)
		stdPolyfills.ffi.free(bytesWrittenSlot)

		error(`DAVE decrypt failed: {decryptorResultMessages[resultCode] or `unknown error (code {resultCode})`}`, 2)
	end

	local bytesWritten = Buffer.readSizeT(bytesWrittenSlot)

	stdPolyfills.ffi.free(bytesWrittenSlot)

	local result = buffer.create(bytesWritten)

	outputPointer:read(0, result, 0, bytesWritten)

	stdPolyfills.ffi.free(outputPointer)

	return result
end

--[=[
	@within Dave.Decryptor

	Returns a snapshot of decryption statistics for `mediaType`. Statistics are cumulative
	since the decryptor was created. `mediaType` should be a value from `Dave.sys.mediaType`.
]=]
function Decryptor.Prototype.getStats(self: Decryptor, mediaType: number): DecryptorStats
	local handle = assert(self.handle, "Decryptor has been destroyed")
	local structType = Sys.structs.decryptorStats
	local statsBuffer = structType:new({})
	local statsPointer = stdPolyfills.ffi.dupe(statsBuffer)

	Sys.lib.daveDecryptorGetStats(handle, mediaType, statsPointer)

	local result: DecryptorStats = {
		passthroughCount = Buffer.readU64AtOffset(statsPointer, structType:offset("passthroughCount")),
		decryptSuccessCount = Buffer.readU64AtOffset(statsPointer, structType:offset("decryptSuccessCount")),
		decryptFailureCount = Buffer.readU64AtOffset(statsPointer, structType:offset("decryptFailureCount")),
		decryptDuration = Buffer.readU64AtOffset(statsPointer, structType:offset("decryptDuration")),
		decryptAttempts = Buffer.readU64AtOffset(statsPointer, structType:offset("decryptAttempts")),
		decryptMissingKeyCount = Buffer.readU64AtOffset(statsPointer, structType:offset("decryptMissingKeyCount")),
		decryptInvalidNonceCount = Buffer.readU64AtOffset(statsPointer, structType:offset("decryptInvalidNonceCount")),
	}

	stdPolyfills.ffi.free(statsPointer)

	return result
end

--[=[
	@within Dave.Decryptor

	Destroys the decryptor and frees all associated libdave resources. The decryptor must
	not be used after this call.
]=]
function Decryptor.Prototype.destroy(self: Decryptor)
	local handle = self.handle

	self.handle = nil

	if handle then
		Sys.lib.daveDecryptorDestroy(handle)
	end
end

--[=[
	@within Dave.Decryptor

	Constructs a new Decryptor.
]=]
function Decryptor.Interface.new(): Decryptor
	local handle = Buffer.adopt(Sys.lib.daveDecryptorCreate(), Sys.pointers.decryptorHandle)

	assert(handle, "daveDecryptorCreate returned NULL")

	return setmetatable({ handle = handle :: Sys.DecryptorHandle? } :: Decryptor, { __index = Decryptor.Prototype })
end

export type DecryptorStats = {
	passthroughCount: number,
	decryptSuccessCount: number,
	decryptFailureCount: number,
	decryptDuration: number,
	decryptAttempts: number,
	decryptMissingKeyCount: number,
	decryptInvalidNonceCount: number,
}

export type Decryptor = typeof(Decryptor.Prototype) & {
	handle: Sys.DecryptorHandle?,
}

return Decryptor.Interface
