--[=[
	@class Dave.Session
	@__index Prototype

	Manages a single MLS (Messaging Layer Security) session for Discord's DAVE protocol.

	A session handles the cryptographic group state shared between participants in a voice
	channel. Its responsibilities include:

	1. Initialising the MLS group for a given voice channel and protocol version
	2. Processing incoming MLS proposals, commits, and welcome messages
	3. Producing key packages that allow other participants to add this client to the group
	4. Deriving per-user key ratchets that feed into the Encryptor and Decryptor
	5. Computing pairwise identity fingerprints for out-of-band verification

	In normal operation the Discord voice server acts as an external sender: it sends the
	`setExternalSender` payload first, then relays proposal/commit/welcome messages between
	participants. `getMarshalledKeyPackage` returns an empty buffer until `setExternalSender`
	has been called and the session has a valid MLS leaf node.
]=]

--[=[
	@prop handle Sys.SessionHandle
	@within Dave.Session
]=]

--[=[
	@prop mlsFailureClosure FFIPointer
	@within Dave.Session
]=]

--[=[
	@prop mlsFailureCallbackRef { current: ((source: string, reason: string) -> ())? }
	@within Dave.Session
]=]

local stdPolyfills = require("../luau_packages/std_polyfills")
local Logger = require("../luau_packages/logger")
local Sys = require("./sys")
local Buffer = require("./buffer")
local KeyRatchet = require("./keyRatchet")
local CommitResult = require("./commitResult")
local WelcomeResult = require("./welcomeResult")

local logger = Logger.new("Dave.Session")

local Session = {}

Session.Interface = {}
Session.Prototype = {}

local function makeForwarderClosure(callbackRef: { current: ((source: string, reason: string) -> ())? }): FFIPointer
	local types = stdPolyfills.ffi.getTypes()

	return stdPolyfills.ffi.closure({
		returns = types.void,
		args = { types.pointer, types.pointer, types.pointer },
	}, function(sourcePointer: FFIPointer, reasonPointer: FFIPointer)
		-- errors must not escape C closure boundaries or Zune panics
		pcall(function()
			local callback = callbackRef.current

			if callback ~= nil then
				local sourceSuccess, source = pcall(Buffer.fromCString, sourcePointer)
				local reasonSuccess, reason = pcall(Buffer.fromCString, reasonPointer)

				callback(if sourceSuccess then source else "", if reasonSuccess then reason else "")
			end
		end)

		return
	end)
end

--[=[
	@within Dave.Session

	Initialises the MLS group state for the given protocol version, voice channel group ID,
	and local user ID. Must be called before `getMarshalledKeyPackage` or any proposal/commit
	processing. `setExternalSender` must also be called *(with data from the voice server)*
	before the session can produce a valid key package.
]=]
function Session.Prototype.init(self: Session, version: number, groupId: string, selfUserId: string)
	local groupIdBuffer = Buffer.u64StringToBuffer(groupId)
	local userIdPointer = Buffer.toCString(selfUserId)

	Sys.lib.daveSessionInit(self.handle, version, groupIdBuffer :: any, userIdPointer)

	stdPolyfills.ffi.free(userIdPointer)
end

--[=[
	@within Dave.Session

	Resets the session back to its uninitialised state, discarding all MLS group state.
	The session must be re-initialised via `init` before it can be used again.
]=]
function Session.Prototype.reset(self: Session)
	Sys.lib.daveSessionReset(self.handle)
end

--[=[
	@within Dave.Session

	Overrides the protocol version in use without fully re-initialising the session. Used
	when the voice server signals a version upgrade mid-session.
]=]
function Session.Prototype.setProtocolVersion(self: Session, version: number)
	Sys.lib.daveSessionSetProtocolVersion(self.handle, version)
end

--[=[
	@within Dave.Session

	Returns the protocol version currently active on the session. Returns `0` if the
	session has not yet been initialised.
]=]
function Session.Prototype.getProtocolVersion(self: Session): number
	return Sys.lib.daveSessionGetProtocolVersion(self.handle)
end

--[=[
	@within Dave.Session

	Returns the authenticator bytes for the most recently committed MLS epoch. The
	authenticator uniquely identifies the current group state and can be compared across
	participants to detect tampering.
	
	Returns an empty buffer before any commit has been processed.
]=]
function Session.Prototype.getLastEpochAuthenticator(self: Session): buffer
	local dataSlot = Buffer.allocateSlot()
	local lengthSlot = Buffer.allocateSlot()

	Sys.lib.daveSessionGetLastEpochAuthenticator(self.handle, dataSlot, lengthSlot)

	local result = Buffer.readLibBytes(dataSlot, lengthSlot)

	stdPolyfills.ffi.free(dataSlot)
	stdPolyfills.ffi.free(lengthSlot)

	return result
end

--[=[
	@within Dave.Session

	Provides the external sender credential package received from the Discord voice server.
	This must be called before the session can produce a valid MLS key package.
]=]
function Session.Prototype.setExternalSender(self: Session, data: buffer)
	local dataPointer = stdPolyfills.ffi.dupe(data)

	Sys.lib.daveSessionSetExternalSender(self.handle, dataPointer, buffer.len(data))

	stdPolyfills.ffi.free(dataPointer)
end

--[=[
	@within Dave.Session

	Processes one or more serialised MLS proposal messages from other participants and
	produces a combined commit+welcome message to be relayed back through the voice server.
	
	Returns `nil` when there is nothing to commit (e.g. the proposals were redundant).
	`recognizedUserIds` should be the full set of user IDs currently known to be in the
	channel.
]=]
function Session.Prototype.processProposals(self: Session, proposals: buffer, recognizedUserIds: { string }): buffer?
	local proposalsPointer = stdPolyfills.ffi.dupe(proposals)
	local dataSlot = Buffer.allocateSlot()
	local lengthSlot = Buffer.allocateSlot()

	Buffer.withCStringArray(recognizedUserIds, function(userIdsPointer, userIdsCount)
		Sys.lib.daveSessionProcessProposals(
			self.handle,
			proposalsPointer,
			buffer.len(proposals),
			userIdsPointer,
			userIdsCount,
			dataSlot,
			lengthSlot
		)
	end)

	stdPolyfills.ffi.free(proposalsPointer)

	local length = Buffer.readSizeT(lengthSlot)

	if length == 0 then
		stdPolyfills.ffi.free(dataSlot)
		stdPolyfills.ffi.free(lengthSlot)

		return nil
	end

	local result = Buffer.readLibBytes(dataSlot, lengthSlot)

	stdPolyfills.ffi.free(dataSlot)
	stdPolyfills.ffi.free(lengthSlot)

	return result
end

--[=[
	@within Dave.Session

	Applies a serialised MLS commit message to advance the group epoch. Returns a
	`CommitResult` describing the new roster state. Inspect `CommitResult:isFailed()` to
	detect hard rejections and `CommitResult:isIgnored()` for soft rejections.
]=]
function Session.Prototype.processCommit(self: Session, commit: buffer): CommitResult.CommitResult
	local commitPointer = stdPolyfills.ffi.dupe(commit)
	local resultHandle = Sys.lib.daveSessionProcessCommit(self.handle, commitPointer, buffer.len(commit))

	stdPolyfills.ffi.free(commitPointer)

	return CommitResult.new(resultHandle)
end

--[=[
	@within Dave.Session

	Processes an MLS welcome message to join an existing group as a new participant.
	Returns a `WelcomeResult` containing the initial roster. `recognizedUserIds` should
	list every user ID this client considers valid for this channel.
]=]
function Session.Prototype.processWelcome(
	self: Session,
	welcome: buffer,
	recognizedUserIds: { string }
): WelcomeResult.WelcomeResult?
	local welcomePointer = stdPolyfills.ffi.dupe(welcome)
	local resultHandle: Sys.WelcomeResultHandle = nil :: any

	Buffer.withCStringArray(recognizedUserIds, function(userIdsPointer, userIdsCount)
		resultHandle = Sys.lib.daveSessionProcessWelcome(
			self.handle,
			welcomePointer,
			buffer.len(welcome),
			userIdsPointer,
			userIdsCount
		)
	end)

	stdPolyfills.ffi.free(welcomePointer)

	-- daveSessionProcessWelcome returns nullptr on failure (e.g. welcome not for our key package).
	-- Detect null by round-tripping the handle through a u64 slot - address 0 == null.
	local checkSlot = Buffer.allocateSlot()
	checkSlot:writeptr(0, resultHandle)
	local isNull = Buffer.readSizeT(checkSlot) == 0
	stdPolyfills.ffi.free(checkSlot)

	if isNull then
		return nil
	end

	return WelcomeResult.new(resultHandle)
end

--[=[
	@within Dave.Session

	Returns the serialised MLS key package for this session, which other participants
	send as a proposal to add this client to the group.
	
	Returns an empty buffer if the session does not yet have a valid leaf node *(i.e.
	`setExternalSender` has not been called yet)*.
]=]
function Session.Prototype.getMarshalledKeyPackage(self: Session): buffer
	local dataSlot = Buffer.allocateSlot()
	local lengthSlot = Buffer.allocateSlot()

	Sys.lib.daveSessionGetMarshalledKeyPackage(self.handle, dataSlot, lengthSlot)

	local result = Buffer.readLibBytes(dataSlot, lengthSlot)

	stdPolyfills.ffi.free(dataSlot)
	stdPolyfills.ffi.free(lengthSlot)

	return result
end

--[=[
	@within Dave.Session

	Derives a `KeyRatchet` for the given user ID from the current MLS group state.
	The ratchet is passed to an `Encryptor` or `Decryptor` to enable authenticated
	encryption for that participant's media stream.
]=]
function Session.Prototype.getKeyRatchet(self: Session, userId: string): KeyRatchet.KeyRatchet
	local userIdPointer = Buffer.toCString(userId)
	local handle = Sys.lib.daveSessionGetKeyRatchet(self.handle, userIdPointer)

	stdPolyfills.ffi.free(userIdPointer)

	return KeyRatchet.new(handle)
end

--[=[
	@within Dave.Session

	Computes and returns the pairwise identity fingerprint between this client and
	`userId` as a lowercase hex string. The fingerprint is derived from both parties'
	MLS leaf credentials and can be compared out-of-band to verify there is no
	man-in-the-middle.
	
	The callback fires synchronously inside libdave.
]=]
function Session.Prototype.getPairwiseFingerprint(self: Session, version: number, userId: string): string?
	local types = stdPolyfills.ffi.getTypes()
	local captured: string? = nil

	local fingerprintClosure = stdPolyfills.ffi.closure({
		returns = types.void,
		args = { types.pointer, types.u64, types.pointer },
	}, function(fingerprintPointer: FFIPointer, lengthValue: any, _userData: any)
		captured = Buffer.bufferToHex(Buffer.readPointerBytes(fingerprintPointer, lengthValue))
		return
	end)

	local userIdPointer = Buffer.toCString(userId)
	local nullPointer = stdPolyfills.ffi.getNull()

	Sys.lib.daveSessionGetPairwiseFingerprint(self.handle, version, userIdPointer, fingerprintClosure, nullPointer)

	stdPolyfills.ffi.free(userIdPointer)

	return captured
end

--[=[
	@within Dave.Session

	Replaces the MLS failure callback without re-creating the session. The new callback
	will be invoked for any subsequent MLS failures on this session.
]=]
function Session.Prototype.setMlsFailureCallback(self: Session, callback: (source: string, reason: string) -> ())
	self.mlsFailureCallbackRef.current = callback
end

--[=[
	@within Dave.Session

	Destroys the session and frees all associated libdave resources. The session must
	not be used after this call.
]=]
function Session.Prototype.destroy(self: Session)
	Sys.lib.daveSessionDestroy(self.handle)
end

--[=[
	@within Dave.Session

	Constructs a new DAVE session. `authSessionId` is an opaque string used by the
	library to persist MLS signature keys across restarts. `onMlsFailure` is called
	if the library encounters a hard MLS error; it can be replaced later via
	`setMlsFailureCallback`.
]=]
function Session.Interface.new(authSessionId: string, onMlsFailure: ((source: string, reason: string) -> ())?): Session
	local callbackRef: { current: ((source: string, reason: string) -> ())? } = {
		current = onMlsFailure,
	}

	local mlsFailureClosure = makeForwarderClosure(callbackRef)

	local authSessionIdPointer = Buffer.toCString(authSessionId)
	local nullPointer = stdPolyfills.ffi.getNull()

	local handle = Sys.lib.daveSessionCreate(nullPointer, authSessionIdPointer, mlsFailureClosure, nullPointer)

	stdPolyfills.ffi.free(authSessionIdPointer)

	return setmetatable(
		{
			handle = handle,
			mlsFailureClosure = mlsFailureClosure,
			mlsFailureCallbackRef = callbackRef,
		} :: Session,
		{ __index = Session.Prototype }
	)
end

export type Session = typeof(Session.Prototype) & {
	handle: Sys.SessionHandle,
	mlsFailureClosure: FFIPointer,
	mlsFailureCallbackRef: { current: ((source: string, reason: string) -> ())? },
}

return Session.Interface
