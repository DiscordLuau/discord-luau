--[=[
	@class Dave

	Entry point for the DAVE (Discord Audio/Video Encryption) end-to-end encryption protocol.

	DAVE provides authenticated encryption for Discord voice channels using MLS
	(Messaging Layer Security). The typical lifecycle for a client joining a voice channel is:

	1. Create a `Session` and call `init` with the protocol version and channel group ID.
	2. Call `setExternalSender` with the credential package provided by the voice server.
	3. Receive the client's `getMarshalledKeyPackage` bytes and send them to the voice server
	   as an MLS proposal.
	4. Process incoming `processProposals` / `processCommit` / `processWelcome` messages
	   relayed by the voice server to advance the group epoch.
	5. After each epoch change, call `Session:getKeyRatchet` for each participant and pass
	   the result to the appropriate `Encryptor` or `Decryptor`.
	6. Pass every outgoing media frame through `Encryptor:encrypt` and every incoming frame
	   through `Decryptor:decrypt`.

	`setLogSinkCallback` can be used to route libdave's internal log output into the
	application's own logging system.
]=]

--[=[
	@prop sys Dave.Sys
	@within Dave

	Raw FFI bindings and constants for libdave. Exposes codec IDs, media type constants,
	result codes, and the underlying C function table. Prefer the higher-level classes
	over calling `sys.lib` directly.
]=]

--[=[
	@prop Session Dave.Session
	@within Dave
]=]

--[=[
	@prop Encryptor Dave.Encryptor
	@within Dave
]=]

--[=[
	@prop Decryptor Dave.Decryptor
	@within Dave
]=]

--[=[
	@prop KeyRatchet Dave.KeyRatchet
	@within Dave
]=]

--[=[
	@prop CommitResult Dave.CommitResult
	@within Dave
]=]

--[=[
	@prop WelcomeResult Dave.WelcomeResult
	@within Dave
]=]

--[=[
	@prop Buffer Dave.Buffer
	@within Dave

	Internal FFI interoperability helpers. Not part of the public API.
]=]

--[=[
	@function setLogSinkCallback
	@param callback (severity: number, message: string) -> ()
	@within Dave

	Registers a global callback that receives all log messages emitted by libdave.
	`severity` maps to `Dave.sys.loggingSeverity` constants. Set this early in
	startup if you want to capture verbose or debug output from the library.
]=]

local stdPolyfills = require("./luau_packages/std_polyfills")
local Sys = require("@self/sys")
local Session = require("@self/session")
local KeyRatchet = require("@self/keyRatchet")
local Encryptor = require("@self/encryptor")
local Decryptor = require("@self/decryptor")
local CommitResult = require("@self/commitResult")
local WelcomeResult = require("@self/welcomeResult")
local Buffer = require("@self/buffer")

local _logSinkClosure: FFIPointer? = nil

export type Session = Session.Session
export type Encryptor = Encryptor.Encryptor
export type Decryptor = Decryptor.Decryptor
export type KeyRatchet = KeyRatchet.KeyRatchet
export type CommitResult = CommitResult.CommitResult
export type WelcomeResult = WelcomeResult.WelcomeResult

return {
	sys = Sys,
	Session = Session,
	KeyRatchet = KeyRatchet,
	Encryptor = Encryptor,
	Decryptor = Decryptor,
	CommitResult = CommitResult,
	WelcomeResult = WelcomeResult,
	Buffer = Buffer,

	setLogSinkCallback = function(callback: (severity: number, message: string) -> ())
		local types = stdPolyfills.ffi.getTypes()
		local closure = stdPolyfills.ffi.closure({
			returns = types.void,
			args = { types.i32, types.pointer, types.i32, types.pointer },
		}, function(severity: number, _filePtr: FFIPointer, _line: number, messagePtr: FFIPointer)
			-- errors must not escape C closure boundaries or Zune panics
			pcall(function()
				local success, message = pcall(Buffer.fromCString, messagePtr)

				callback(severity, if success then message else "")
			end)

			return
		end)

		_logSinkClosure = closure

		Sys.lib.daveSetLogSinkCallback(closure)
	end,
}
