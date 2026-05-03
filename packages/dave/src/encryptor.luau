--[=[
	@class Dave.Encryptor
	@__index Prototype

	Encrypts outgoing media frames using the DAVE protocol.

	An Encryptor operates on a single send stream. Once a `KeyRatchet` is set via
	`setKeyRatchet`, each call to `encrypt` advances the ratchet and produces an
	authenticated ciphertext. Before a ratchet is available (e.g. while the MLS group is
	being established), call `setPassthroughMode(true)` to forward frames unmodified.

	```luau
	local enc = Dave.Encryptor.new()

	enc:assignSsrcToCodec(ssrc, Dave.sys.codec.opus)
	enc:setKeyRatchet(session:getKeyRatchet(selfUserId))

	local encrypted = enc:encrypt(Dave.sys.mediaType.audio, ssrc, rawFrame)
	```
]=]

--[=[
	@prop handle Sys.EncryptorHandle
	@within Dave.Encryptor
]=]

--[=[
	@prop versionChangedClosure FFIPointer
	@within Dave.Encryptor
]=]

--[=[
	@prop versionChangedCallbackRef { current: (() -> ())? }
	@within Dave.Encryptor
]=]

local stdPolyfills = require("../luau_packages/std_polyfills")
local Logger = require("../luau_packages/logger")
local Sys = require("./sys")
local Buffer = require("./buffer")
local KeyRatchet = require("./keyRatchet")

local logger = Logger.new("Dave.Encryptor")

local Encryptor = {}

Encryptor.Interface = {}
Encryptor.Prototype = {}

export type EncryptorStats = {
	passthroughCount: number,
	encryptSuccessCount: number,
	encryptFailureCount: number,
	encryptDuration: number,
	encryptAttempts: number,
	encryptMaxAttempts: number,
	encryptMissingKeyCount: number,
}

local encryptorResultMessages: { [number]: string }?

--[=[
	@within Dave.Encryptor

	Sets the key ratchet used for encryption. Derives fresh keys on each frame from the
	given ratchet. Obtain a ratchet from `Session:getKeyRatchet(selfUserId)` after the
	MLS group has been established.
]=]
function Encryptor.Prototype.setKeyRatchet(self: Encryptor, keyRatchet: KeyRatchet.KeyRatchet)
	Sys.lib.daveEncryptorSetKeyRatchet(self.handle, keyRatchet.handle)
end

--[=[
	@within Dave.Encryptor

	Enables or disables passthrough mode. When enabled, frames are forwarded to `encrypt`
	callers unchanged without consuming key material. Use this while the MLS group is not
	yet ready.
]=]
function Encryptor.Prototype.setPassthroughMode(self: Encryptor, enabled: boolean)
	Sys.lib.daveEncryptorSetPassthroughMode(self.handle, if enabled then 1 else 0)
end

--[=[
	@within Dave.Encryptor

	Returns `true` if a key ratchet has been set on this encryptor.
]=]
function Encryptor.Prototype.hasKeyRatchet(self: Encryptor): boolean
	return Sys.lib.daveEncryptorHasKeyRatchet(self.handle) ~= 0
end

--[=[
	@within Dave.Encryptor

	Returns `true` if the encryptor is currently in passthrough mode.
]=]
function Encryptor.Prototype.isPassthroughMode(self: Encryptor): boolean
	return Sys.lib.daveEncryptorIsPassthroughMode(self.handle) ~= 0
end

--[=[
	@within Dave.Encryptor

	Associates `ssrc` with `codec` so the encryptor knows how to frame-parse the stream.
	Must be called for each SSRC before the first `encrypt` call for that stream.
	`codec` should be a value from `Dave.sys.codec`.
]=]
function Encryptor.Prototype.assignSsrcToCodec(self: Encryptor, ssrc: number, codec: number)
	Sys.lib.daveEncryptorAssignSsrcToCodec(self.handle, ssrc, codec)
end

--[=[
	@within Dave.Encryptor

	Returns the DAVE protocol version this encryptor is currently operating at.
]=]
function Encryptor.Prototype.getProtocolVersion(self: Encryptor): number
	return Sys.lib.daveEncryptorGetProtocolVersion(self.handle)
end

--[=[
	@within Dave.Encryptor

	Returns the maximum number of bytes that `encrypt` may write for a plaintext frame of
	`frameSize` bytes on `mediaType`. Use this to pre-allocate output buffers or to
	validate output size expectations.
]=]
function Encryptor.Prototype.getMaxCiphertextByteSize(self: Encryptor, mediaType: number, frameSize: number): number
	return Buffer.readRawU64(Sys.lib.daveEncryptorGetMaxCiphertextByteSize(self.handle, mediaType, frameSize))
end

--[=[
	@within Dave.Encryptor

	Encrypts `frame` and returns the ciphertext as a new buffer. The SSRC must have been
	registered via `assignSsrcToCodec`. Logs an error and halts the calling coroutine on
	any non-success result code (missing ratchet, too many retries, etc.).
]=]
function Encryptor.Prototype.encrypt(self: Encryptor, mediaType: number, ssrc: number, frame: buffer): buffer
	local frameSize = buffer.len(frame)
	local maxOutputSize = self:getMaxCiphertextByteSize(mediaType, frameSize)
	local outputPointer = stdPolyfills.ffi.alloc(maxOutputSize, 1)
	local framePointer = stdPolyfills.ffi.dupe(frame)
	local bytesWrittenSlot = Buffer.allocateSlot()

	local resultCode = Sys.lib.daveEncryptorEncrypt(
		self.handle,
		mediaType,
		ssrc,
		framePointer,
		frameSize,
		outputPointer,
		maxOutputSize,
		bytesWrittenSlot
	)

	stdPolyfills.ffi.free(framePointer)

	if resultCode ~= Sys.encryptorResultCode.success then
		stdPolyfills.ffi.free(outputPointer)
		stdPolyfills.ffi.free(bytesWrittenSlot)

		if not encryptorResultMessages then
			encryptorResultMessages = {
				[Sys.encryptorResultCode.encryptionFailure] = "encryption failure",
				[Sys.encryptorResultCode.missingKeyRatchet] = "missing key ratchet",
				[Sys.encryptorResultCode.missingCryptor] = "missing cryptor",
				[Sys.encryptorResultCode.tooManyAttempts] = "too many attempts",
			}
		end

		logger:error((encryptorResultMessages :: { [number]: string })[resultCode] or `unknown error (code {resultCode})`)
	end

	local bytesWritten = Buffer.readSizeT(bytesWrittenSlot)

	stdPolyfills.ffi.free(bytesWrittenSlot)

	local result = buffer.create(bytesWritten)

	outputPointer:read(0, result, 0, bytesWritten)

	stdPolyfills.ffi.free(outputPointer)

	return result
end

--[=[
	@within Dave.Encryptor

	Registers a callback that fires whenever the encryptor's protocol version changes
	(e.g. after the voice server negotiates an upgrade). Replaces any previously set
	callback without re-registering with the library.
]=]
function Encryptor.Prototype.setProtocolVersionChangedCallback(self: Encryptor, callback: () -> ())
	self.versionChangedCallbackRef.current = callback
end

--[=[
	@within Dave.Encryptor

	Returns a snapshot of encryption statistics for `mediaType`. Statistics are cumulative
	since the encryptor was created. `mediaType` should be a value from `Dave.sys.mediaType`.
]=]
function Encryptor.Prototype.getStats(self: Encryptor, mediaType: number): EncryptorStats
	local structType = Sys.structs.encryptorStats
	local statsBuffer = structType:new({})
	local statsPointer = stdPolyfills.ffi.dupe(statsBuffer)

	Sys.lib.daveEncryptorGetStats(self.handle, mediaType, statsPointer)

	local result: EncryptorStats = {
		passthroughCount = Buffer.readU64AtOffset(statsPointer, structType:offset("passthroughCount")),
		encryptSuccessCount = Buffer.readU64AtOffset(statsPointer, structType:offset("encryptSuccessCount")),
		encryptFailureCount = Buffer.readU64AtOffset(statsPointer, structType:offset("encryptFailureCount")),
		encryptDuration = Buffer.readU64AtOffset(statsPointer, structType:offset("encryptDuration")),
		encryptAttempts = Buffer.readU64AtOffset(statsPointer, structType:offset("encryptAttempts")),
		encryptMaxAttempts = Buffer.readU64AtOffset(statsPointer, structType:offset("encryptMaxAttempts")),
		encryptMissingKeyCount = Buffer.readU64AtOffset(statsPointer, structType:offset("encryptMissingKeyCount")),
	}

	stdPolyfills.ffi.free(statsPointer)

	return result
end

--[=[
	@within Dave.Encryptor

	Destroys the encryptor and frees all associated libdave resources. The encryptor must
	not be used after this call.
]=]
function Encryptor.Prototype.destroy(self: Encryptor)
	Sys.lib.daveEncryptorDestroy(self.handle)
end

--[=[
	@within Dave.Encryptor

	Constructs a new Encryptor. Registers a stable forwarder closure for the
	protocol-version-changed callback so the Luau handler can be swapped later via
	`setProtocolVersionChangedCallback`.
]=]
function Encryptor.Interface.new(): Encryptor
	local versionChangedCallbackRef: { current: (() -> ())? } = { current = nil }
	local handle = Sys.lib.daveEncryptorCreate()

	local types = stdPolyfills.ffi.getTypes()
	local versionChangedClosure = stdPolyfills.ffi.closure({
		returns = types.void,
		args = { types.pointer },
	}, function(_userData: FFIPointer)
		pcall(function()
			local callback = versionChangedCallbackRef.current

			if callback ~= nil then
				callback()
			end
		end)

		return
	end)

	local nullPointer = stdPolyfills.ffi.getNull()
	Sys.lib.daveEncryptorSetProtocolVersionChangedCallback(handle, versionChangedClosure, nullPointer)

	return setmetatable(
		{
			handle = handle,
			versionChangedClosure = versionChangedClosure,
			versionChangedCallbackRef = versionChangedCallbackRef,
		} :: Encryptor,
		{ __index = Encryptor.Prototype }
	)
end

export type Encryptor = typeof(Encryptor.Prototype) & {
	handle: Sys.EncryptorHandle,
	versionChangedClosure: FFIPointer,
	versionChangedCallbackRef: { current: (() -> ())? },
}

return Encryptor.Interface
