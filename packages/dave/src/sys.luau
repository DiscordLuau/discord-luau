--!strict
--!optimize 2
--!native

--[=[
	@class Dave.Sys

	Raw FFI bindings for libdave — the C interface to Discord's DAVE end-to-end encryption protocol.

	This module loads libdave via `stdPolyfills.ffi.dlopen` and exposes the full C API as a typed Luau
	interface. It is a low-level binding layer; higher-level wrappers should be built on top of
	`lib` rather than consuming this module directly.
]=]

--[=[
	@prop lib Lib
	@within Dave.Sys

	The loaded libdave FFI library. All DAVE protocol functions are called through this handle.
]=]

--[=[
	@prop structs { encryptorStats: FFIStructureType, decryptorStats: FFIStructureType }
	@within Dave.Sys
]=]

--[=[
	@prop pointers { sessionHandle: FFIPointerType, commitResultHandle: FFIPointerType, welcomeResultHandle: FFIPointerType, keyRatchetHandle: FFIPointerType, encryptorHandle: FFIPointerType, decryptorHandle: FFIPointerType }
	@within Dave.Sys
]=]

--[=[
	@prop codec { unknown: number, opus: number, vp8: number, vp9: number, h264: number, h265: number, av1: number }
	@within Dave.Sys
]=]

--[=[
	@prop mediaType { audio: number, video: number }
	@within Dave.Sys
]=]

--[=[
	@prop encryptorResultCode { success: number, encryptionFailure: number, missingKeyRatchet: number, missingCryptor: number, tooManyAttempts: number }
	@within Dave.Sys
]=]

--[=[
	@prop decryptorResultCode { success: number, decryptionFailure: number, missingKeyRatchet: number, invalidNonce: number, missingCryptor: number }
	@within Dave.Sys
]=]

--[=[
	@prop loggingSeverity { verbose: number, info: number, warning: number, error: number, none: number }
	@within Dave.Sys
]=]

local stdPolyfills = require("../luau_packages/std_polyfills")

local types = stdPolyfills.ffi.getTypes()

local void = types.void
local u8 = types.u8
local u16 = types.u16
local u32 = types.u32
local u64 = types.u64
local i32 = types.i32

local cEnum = i32
local cBool = u8
local cSizeT = u64
local pointer = types.pointer

local SessionHandle = pointer:newTag("DAVESessionHandle")
local CommitResultHandle = pointer:newTag("DAVECommitResultHandle")
local WelcomeResultHandle = pointer:newTag("DAVEWelcomeResultHandle")
local KeyRatchetHandle = pointer:newTag("DAVEKeyRatchetHandle")
local EncryptorHandle = pointer:newTag("DAVEEncryptorHandle")
local DecryptorHandle = pointer:newTag("DAVEDecryptorHandle")

local EncryptorStats = stdPolyfills.ffi.struct({
	{ passthroughCount = u64 },
	{ encryptSuccessCount = u64 },
	{ encryptFailureCount = u64 },
	{ encryptDuration = u64 },
	{ encryptAttempts = u64 },
	{ encryptMaxAttempts = u64 },
	{ encryptMissingKeyCount = u64 },
})

local DecryptorStats = stdPolyfills.ffi.struct({
	{ passthroughCount = u64 },
	{ decryptSuccessCount = u64 },
	{ decryptFailureCount = u64 },
	{ decryptDuration = u64 },
	{ decryptAttempts = u64 },
	{ decryptMissingKeyCount = u64 },
	{ decryptInvalidNonceCount = u64 },
})

export type SessionHandle = FFIPointer
export type CommitResultHandle = FFIPointer
export type WelcomeResultHandle = FFIPointer
export type KeyRatchetHandle = FFIPointer
export type EncryptorHandle = FFIPointer
export type DecryptorHandle = FFIPointer

export type DecryptorStats = typeof(DecryptorStats:new({}))

export type EncryptorStats = typeof(EncryptorStats:new({}))

export type Lib = {
	daveMaxSupportedProtocolVersion: () -> number,

	daveFree: (ptr: FFIPointer) -> (),

	daveSessionCreate: (
		context: FFIPointer,
		authSessionId: FFIPointer,
		onMlsFailure: FFIPointer,
		userData: FFIPointer
	) -> SessionHandle,
	daveSessionDestroy: (session: SessionHandle) -> (),
	daveSessionInit: (session: SessionHandle, version: number, groupId: buffer, selfUserId: FFIPointer) -> (),
	daveSessionReset: (session: SessionHandle) -> (),
	daveSessionSetProtocolVersion: (session: SessionHandle, version: number) -> (),
	daveSessionGetProtocolVersion: (session: SessionHandle) -> number,
	daveSessionGetLastEpochAuthenticator: (session: SessionHandle, outData: FFIPointer, outLength: FFIPointer) -> (),
	daveSessionSetExternalSender: (session: SessionHandle, data: FFIPointer, length: number) -> (),
	daveSessionProcessProposals: (
		session: SessionHandle,
		proposals: FFIPointer,
		length: number,
		userIds: FFIPointer,
		userIdsLength: number,
		outCommit: FFIPointer,
		outLength: FFIPointer
	) -> (),
	daveSessionProcessCommit: (session: SessionHandle, commit: FFIPointer, length: number) -> CommitResultHandle,
	daveSessionProcessWelcome: (
		session: SessionHandle,
		welcome: FFIPointer,
		length: number,
		userIds: FFIPointer,
		userIdsLength: number
	) -> WelcomeResultHandle,
	daveSessionGetMarshalledKeyPackage: (session: SessionHandle, outData: FFIPointer, outLength: FFIPointer) -> (),
	daveSessionGetKeyRatchet: (session: SessionHandle, userId: FFIPointer) -> KeyRatchetHandle,
	daveSessionGetPairwiseFingerprint: (
		session: SessionHandle,
		version: number,
		userId: FFIPointer,
		onFingerprint: FFIPointer,
		userData: FFIPointer
	) -> (),

	daveKeyRatchetDestroy: (keyRatchet: KeyRatchetHandle) -> (),

	daveCommitResultIsFailed: (result: CommitResultHandle) -> number,
	daveCommitResultIsIgnored: (result: CommitResultHandle) -> number,
	daveCommitResultGetRosterMemberIds: (result: CommitResultHandle, outIds: FFIPointer, outLength: FFIPointer) -> (),
	daveCommitResultGetRosterMemberSignature: (
		result: CommitResultHandle,
		rosterId: buffer,
		outData: FFIPointer,
		outLength: FFIPointer
	) -> (),
	daveCommitResultDestroy: (result: CommitResultHandle) -> (),

	daveWelcomeResultGetRosterMemberIds: (result: WelcomeResultHandle, outIds: FFIPointer, outLength: FFIPointer) -> (),
	daveWelcomeResultGetRosterMemberSignature: (
		result: WelcomeResultHandle,
		rosterId: buffer,
		outData: FFIPointer,
		outLength: FFIPointer
	) -> (),
	daveWelcomeResultDestroy: (result: WelcomeResultHandle) -> (),

	daveEncryptorCreate: () -> EncryptorHandle,
	daveEncryptorDestroy: (encryptor: EncryptorHandle) -> (),
	daveEncryptorSetKeyRatchet: (encryptor: EncryptorHandle, keyRatchet: KeyRatchetHandle) -> (),
	daveEncryptorSetPassthroughMode: (encryptor: EncryptorHandle, passthroughMode: number) -> (),
	daveEncryptorAssignSsrcToCodec: (encryptor: EncryptorHandle, ssrc: number, codec: number) -> (),
	daveEncryptorGetProtocolVersion: (encryptor: EncryptorHandle) -> number,
	daveEncryptorGetMaxCiphertextByteSize: (encryptor: EncryptorHandle, mediaType: number, frameSize: number) -> number,
	daveEncryptorHasKeyRatchet: (encryptor: EncryptorHandle) -> number,
	daveEncryptorIsPassthroughMode: (encryptor: EncryptorHandle) -> number,
	daveEncryptorEncrypt: (
		encryptor: EncryptorHandle,
		mediaType: number,
		ssrc: number,
		frame: FFIPointer,
		frameLength: number,
		outFrame: FFIPointer,
		outCapacity: number,
		outBytesWritten: FFIPointer
	) -> number,
	daveEncryptorSetProtocolVersionChangedCallback: (
		encryptor: EncryptorHandle,
		onVersionChanged: FFIPointer,
		userData: FFIPointer
	) -> (),
	daveEncryptorGetStats: (encryptor: EncryptorHandle, mediaType: number, outStats: FFIPointer) -> (),

	daveDecryptorCreate: () -> DecryptorHandle,
	daveDecryptorDestroy: (decryptor: DecryptorHandle) -> (),
	daveDecryptorTransitionToKeyRatchet: (decryptor: DecryptorHandle, keyRatchet: KeyRatchetHandle) -> (),
	daveDecryptorTransitionToPassthroughMode: (decryptor: DecryptorHandle, passthroughMode: number) -> (),
	daveDecryptorDecrypt: (
		decryptor: DecryptorHandle,
		mediaType: number,
		encFrame: FFIPointer,
		encFrameLength: number,
		outFrame: FFIPointer,
		outCapacity: number,
		outBytesWritten: FFIPointer
	) -> number,
	daveDecryptorGetMaxPlaintextByteSize: (
		decryptor: DecryptorHandle,
		mediaType: number,
		encFrameSize: number
	) -> number,
	daveDecryptorGetStats: (decryptor: DecryptorHandle, mediaType: number, outStats: FFIPointer) -> (),

	daveSetLogSinkCallback: (onLog: FFIPointer) -> (),
}

local os = stdPolyfills.process.getPlatform()
local arch = stdPolyfills.process.getArch()

local osName = if os == "linux" then "Linux" elseif os == "macos" then "macOS" else "Windows"
local archName = if arch == "aarch64" then "ARM64" else "X64"
local subdir = if os == "windows" then "bin" else "lib"
local ext = if os == "linux" then "so" elseif os == "macos" then "dylib" else "dll"

local libPath = `{zune.require.navigate("../binaries")}/{osName}-{archName}/{subdir}/libdave.{ext}`

local lib = (
	stdPolyfills.ffi.dlopen(libPath, {
		daveMaxSupportedProtocolVersion = { returns = u16, args = {} },

		daveFree = { returns = void, args = { pointer } },

		daveSessionCreate = { returns = SessionHandle, args = { pointer, pointer, pointer, pointer } },
		daveSessionDestroy = { returns = void, args = { SessionHandle } },
		daveSessionInit = { returns = void, args = { SessionHandle, u16, u64, pointer } },
		daveSessionReset = { returns = void, args = { SessionHandle } },
		daveSessionSetProtocolVersion = { returns = void, args = { SessionHandle, u16 } },
		daveSessionGetProtocolVersion = { returns = u16, args = { SessionHandle } },
		daveSessionGetLastEpochAuthenticator = { returns = void, args = { SessionHandle, pointer, pointer } },
		daveSessionSetExternalSender = { returns = void, args = { SessionHandle, pointer, cSizeT } },
		daveSessionProcessProposals = {
			returns = void,
			args = { SessionHandle, pointer, cSizeT, pointer, cSizeT, pointer, pointer },
		},
		daveSessionProcessCommit = { returns = CommitResultHandle, args = { SessionHandle, pointer, cSizeT } },
		daveSessionProcessWelcome = {
			returns = WelcomeResultHandle,
			args = { SessionHandle, pointer, cSizeT, pointer, cSizeT },
		},
		daveSessionGetMarshalledKeyPackage = { returns = void, args = { SessionHandle, pointer, pointer } },
		daveSessionGetKeyRatchet = { returns = KeyRatchetHandle, args = { SessionHandle, pointer } },
		daveSessionGetPairwiseFingerprint = { returns = void, args = { SessionHandle, u16, pointer, pointer, pointer } },

		daveKeyRatchetDestroy = { returns = void, args = { KeyRatchetHandle } },

		daveCommitResultIsFailed = { returns = cBool, args = { CommitResultHandle } },
		daveCommitResultIsIgnored = { returns = cBool, args = { CommitResultHandle } },
		daveCommitResultGetRosterMemberIds = { returns = void, args = { CommitResultHandle, pointer, pointer } },
		daveCommitResultGetRosterMemberSignature = {
			returns = void,
			args = { CommitResultHandle, u64, pointer, pointer },
		},
		daveCommitResultDestroy = { returns = void, args = { CommitResultHandle } },

		daveWelcomeResultGetRosterMemberIds = { returns = void, args = { WelcomeResultHandle, pointer, pointer } },
		daveWelcomeResultGetRosterMemberSignature = {
			returns = void,
			args = { WelcomeResultHandle, u64, pointer, pointer },
		},
		daveWelcomeResultDestroy = { returns = void, args = { WelcomeResultHandle } },

		daveEncryptorCreate = { returns = EncryptorHandle, args = {} },
		daveEncryptorDestroy = { returns = void, args = { EncryptorHandle } },
		daveEncryptorSetKeyRatchet = { returns = void, args = { EncryptorHandle, KeyRatchetHandle } },
		daveEncryptorSetPassthroughMode = { returns = void, args = { EncryptorHandle, cBool } },
		daveEncryptorAssignSsrcToCodec = { returns = void, args = { EncryptorHandle, u32, cEnum } },
		daveEncryptorGetProtocolVersion = { returns = u16, args = { EncryptorHandle } },
		daveEncryptorGetMaxCiphertextByteSize = { returns = cSizeT, args = { EncryptorHandle, cEnum, cSizeT } },
		daveEncryptorHasKeyRatchet = { returns = cBool, args = { EncryptorHandle } },
		daveEncryptorIsPassthroughMode = { returns = cBool, args = { EncryptorHandle } },
		daveEncryptorEncrypt = {
			returns = cEnum,
			args = { EncryptorHandle, cEnum, u32, pointer, cSizeT, pointer, cSizeT, pointer },
		},
		daveEncryptorSetProtocolVersionChangedCallback = {
			returns = void,
			args = { EncryptorHandle, pointer, pointer },
		},
		daveEncryptorGetStats = { returns = void, args = { EncryptorHandle, cEnum, pointer } },

		daveDecryptorCreate = { returns = DecryptorHandle, args = {} },
		daveDecryptorDestroy = { returns = void, args = { DecryptorHandle } },
		daveDecryptorTransitionToKeyRatchet = { returns = void, args = { DecryptorHandle, KeyRatchetHandle } },
		daveDecryptorTransitionToPassthroughMode = { returns = void, args = { DecryptorHandle, cBool } },
		daveDecryptorDecrypt = {
			returns = cEnum,
			args = { DecryptorHandle, cEnum, pointer, cSizeT, pointer, cSizeT, pointer },
		},
		daveDecryptorGetMaxPlaintextByteSize = { returns = cSizeT, args = { DecryptorHandle, cEnum, cSizeT } },
		daveDecryptorGetStats = { returns = void, args = { DecryptorHandle, cEnum, pointer } },

		daveSetLogSinkCallback = { returns = void, args = { pointer } },
	}) :: any
) :: Lib

return {
	lib = lib,

	structs = {
		encryptorStats = EncryptorStats,
		decryptorStats = DecryptorStats,
	},

	pointers = {
		sessionHandle = SessionHandle,
		commitResultHandle = CommitResultHandle,
		welcomeResultHandle = WelcomeResultHandle,
		keyRatchetHandle = KeyRatchetHandle,
		encryptorHandle = EncryptorHandle,
		decryptorHandle = DecryptorHandle,
	},

	codec = {
		unknown = 0,
		opus = 1,
		vp8 = 2,
		vp9 = 3,
		h264 = 4,
		h265 = 5,
		av1 = 6,
	},

	mediaType = {
		audio = 0,
		video = 1,
	},

	encryptorResultCode = {
		success = 0,
		encryptionFailure = 1,
		missingKeyRatchet = 2,
		missingCryptor = 3,
		tooManyAttempts = 4,
	},

	decryptorResultCode = {
		success = 0,
		decryptionFailure = 1,
		missingKeyRatchet = 2,
		invalidNonce = 3,
		missingCryptor = 4,
	},

	loggingSeverity = {
		verbose = 0,
		info = 1,
		warning = 2,
		error = 3,
		none = 4,
	},
}
