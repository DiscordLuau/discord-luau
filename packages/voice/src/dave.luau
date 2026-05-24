--[=[
	@class Voice.DaveManager
	@__index Prototype

	Manages the DAVE (Discord Audio/Video Encryption) MLS session lifecycle for a voice connection.

	Owns the MLS session, encryptor, per-user decryptors, and SSRC-to-user-ID mapping. Opcode
	handlers return frames to send and roster IDs rather than performing I/O - the caller
	(Voice.Connection) is responsible for sending frames and firing events.
]=]

--[=[
	@prop daveSession dave.Session?
	@within Voice.DaveManager
]=]

--[=[
	@prop pendingDaveProtocolVersion number?
	@within Voice.DaveManager
]=]

--[=[
	@prop isPendingCommitter boolean
	@within Voice.DaveManager
]=]

--[=[
	@prop daveEncryptor dave.Encryptor?
	@within Voice.DaveManager
]=]

--[=[
	@prop daveDecryptors { [string]: dave.Decryptor }
	@within Voice.DaveManager
]=]

--[=[
	@prop recognizedUserIds { string }
	@within Voice.DaveManager
]=]

--[=[
	@prop ssrcToUserId { [number]: string }
	@within Voice.DaveManager
]=]

--[=[
	@prop logger logger.Logger
	@within Voice.DaveManager
]=]

local dave = require("../luau_packages/dave")
local logger = require("../luau_packages/logger")
local apiTypes = require("../luau_packages/api_types")

local daveLogger: logger.Logger
local daveLoggerHasBeenSet = false

local DaveManager = {}

DaveManager.Interface = {}
DaveManager.Prototype = {}

--[=[
	@within Voice.DaveManager

	Destroys the active DAVE session, encryptor, and all per-user decryptors, then resets all state.
]=]
function DaveManager.Prototype.cleanup(self: DaveManager)
	if self.daveSession then
		self.logger:debug(`destroying DAVE session`)
		self.daveSession:destroy()
		self.daveSession = nil
	end

	if self.daveEncryptor then
		self.logger:debug(`destroying DAVE encryptor`)
		self.daveEncryptor:destroy()
		self.daveEncryptor = nil
	end

	for userId, decryptor in self.daveDecryptors do
		self.logger:debug(`destroying decryptor for user={userId}`)
		decryptor:destroy()
		self.daveDecryptors[userId] = nil
	end

	self.pendingDaveProtocolVersion = nil
	self.isPendingCommitter = false
	self.recognizedUserIds = {}
	self.ssrcToUserId = {}
end

--[=[
	@within Voice.DaveManager

	Updates the encryptor key ratchet and rebuilds per-user decryptors from the current MLS roster.
	Destroys decryptors for users no longer in the roster.
]=]
function DaveManager.Prototype.rotateDaveKeys(self: DaveManager, rosterIds: { string }, userId: string, ssrc: number?)
	local daveSession = self.daveSession

	if not daveSession then
		self.logger:debug(`no DAVE session, skipping rotation`)
		return
	end

	local selfRatchet = daveSession:getKeyRatchet(userId)
	local rosterSet: { [string]: boolean } = {}

	for _, memberId in rosterIds do
		rosterSet[memberId] = true
	end

	if not self.daveEncryptor then
		self.logger:debug(`creating new encryptor`)
		self.daveEncryptor = dave.Encryptor.new()

		if ssrc and self.daveEncryptor then
			self.daveEncryptor:assignSsrcToCodec(ssrc, dave.sys.codec.opus)
		end
	end

	if self.daveEncryptor then
		self.daveEncryptor:setKeyRatchet(selfRatchet)
		self.logger:debug(`encryptor key ratchet updated`)
	end

	for _, memberId in rosterIds do
		if memberId == userId then
			continue
		end

		local ratchet = daveSession:getKeyRatchet(memberId)

		if not self.daveDecryptors[memberId] then
			self.logger:debug(`creating decryptor for user={memberId}`)
			self.daveDecryptors[memberId] = dave.Decryptor.new()
		end

		self.daveDecryptors[memberId]:transitionToKeyRatchet(ratchet)
	end

	for memberId, decryptor in self.daveDecryptors do
		if not rosterSet[memberId] then
			self.logger:debug(`destroying decryptor for departed user={memberId}`)
			decryptor:destroy()
			self.daveDecryptors[memberId] = nil
		end
	end

	self.logger:info(`rotation complete, roster={#rosterIds}`)
end

--[=[
	@within Voice.DaveManager

	Creates and initialises a new DAVE MLS session for the given protocol version, channel, and user.
]=]
function DaveManager.Prototype.initSession(
	self: DaveManager,
	protocolVersion: number,
	channelId: string,
	userId: string
)
	self.daveSession = dave.Session.new("", nil)

	if self.daveSession then
		self.daveSession:init(protocolVersion, channelId, userId)
	end
end

--[=[
	@within Voice.DaveManager

	Stores the incoming protocol version and returns a DaveProtocolTransitionReady frame to send to the server.
]=]
function DaveManager.Prototype.handlePrepareTransition(self: DaveManager, payload: any): buffer
	local protocolVersion = payload.protocol_version

	self.logger:info(`DAVE protocol prepare transition: version={protocolVersion}`)

	self.pendingDaveProtocolVersion = protocolVersion

	if self.daveSession then
		self.daveSession:setProtocolVersion(protocolVersion)
		self.logger:debug(`prepare transition: set protocol version to {protocolVersion} on existing session`)
	else
		self.logger:debug(`prepare transition: no active session, version stored for when session initialises`)
	end

	local frame = buffer.create(1)
	buffer.writeu8(frame, 0, apiTypes.voice.opcodes.DaveProtocolTransitionReady)

	return frame
end

--[=[
	@within Voice.DaveManager

	Applies the pending protocol version to the active session and clears the pending state.
]=]
function DaveManager.Prototype.handleExecuteTransition(self: DaveManager, _payload: any)
	local pendingVersion = self.pendingDaveProtocolVersion

	self.logger:info(`DAVE protocol execute transition, pending version={tostring(pendingVersion)}`)

	if pendingVersion then
		self.pendingDaveProtocolVersion = nil

		if self.daveSession then
			self.daveSession:setProtocolVersion(pendingVersion)
			self.logger:debug(`execute transition: applied protocol version {pendingVersion}`)
		else
			self.logger:debug(`execute transition: no active session, pending version cleared`)
		end
	else
		self.logger:debug(`execute transition received but no pending version stored, ignoring`)
	end
end

--[=[
	@within Voice.DaveManager

	Resets or creates the DAVE session in preparation for a new MLS epoch, then initialises it.
]=]
function DaveManager.Prototype.handlePrepareEpoch(self: DaveManager, payload: any, channelId: string, userId: string)
	self.logger:info(`DAVE protocol prepare epoch: version={payload.protocol_version}`)

	if self.daveSession then
		self.logger:debug(`resetting existing DAVE session for new epoch`)
		self.daveSession:reset()
	else
		self.logger:debug(`creating new DAVE session (transient key)`)
		self.daveSession = dave.Session.new("", nil)
	end

	if self.daveSession then
		self.daveSession:init(payload.protocol_version, channelId, userId)
		self.logger:debug(
			`DAVE session initialised: protocol={payload.protocol_version} group={channelId} user={userId}`
		)
	end
end

--[=[
	@within Voice.DaveManager

	Sets the MLS external sender and returns a DaveMlsKeyPackage frame for the server.
]=]
function DaveManager.Prototype.handleExternalSender(self: DaveManager, payload: any): buffer?
	self.logger:info(`received DAVE MLS external sender package`)

	if not self.daveSession then
		self.logger:warn(`received DaveMlsExternalSenderPackage but no DAVE session exists`)
		return nil
	end

	self.daveSession:setExternalSender(payload)
	self.logger:debug(`external sender set, fetching key package`)

	local keyPackage = self.daveSession:getMarshalledKeyPackage()
	local keyPackageLength = buffer.len(keyPackage)

	self.logger:debug(`sending MLS key package: {keyPackageLength} bytes`)

	local frame = buffer.create(1 + keyPackageLength)
	buffer.writeu8(frame, 0, apiTypes.voice.opcodes.DaveMlsKeyPackage)
	buffer.copy(frame, 1, keyPackage, 0, keyPackageLength)

	return frame
end

--[=[
	@within Voice.DaveManager

	Processes incoming MLS proposals and returns a commit+welcome frame and the current roster snapshot.
]=]
function DaveManager.Prototype.handleProposals(
	self: DaveManager,
	payload: any,
	_: string,
	_: number?
): (buffer?, { string }?)
	self.logger:info(`received DAVE MLS proposals`)

	if not self.daveSession then
		self.logger:warn(`received DaveMlsProposals but no DAVE session exists`)
		return
	end

	self.logger:debug(`processing MLS proposals with {#self.recognizedUserIds} recognized user(s)`)

	local rosterSnapshot = self.recognizedUserIds
	local commitWelcome = self.daveSession:processProposals(payload, rosterSnapshot)

	if not commitWelcome then
		self.logger:debug(`processProposals returned nil, nothing to commit`)
		return
	end

	local commitWelcomeLength = buffer.len(commitWelcome)

	self.logger:debug(`sending MLS commit+welcome: {commitWelcomeLength} bytes`)

	self.isPendingCommitter = true

	local frame = buffer.create(1 + commitWelcomeLength)
	buffer.writeu8(frame, 0, apiTypes.voice.opcodes.DaveMlsCommitWelcome)
	buffer.copy(frame, 1, commitWelcome, 0, commitWelcomeLength)

	return frame, rosterSnapshot
end

--[=[
	@within Voice.DaveManager

	Processes an MLS commit, advances the epoch, and rotates encryption keys for the new roster.
	Returns the updated roster member IDs, or nil if the commit was rejected or ignored.
]=]
function DaveManager.Prototype.handleCommitTransition(
	self: DaveManager,
	payload: any,
	userId: string,
	ssrc: number?
): { string }?
	self.logger:info(`received DAVE MLS commit transition`)

	if not self.daveSession then
		self.logger:debug(`DaveMlsAnnounceCommitTransition: no DAVE session, skipping`)
		return nil
	end

	local transitionId = bit32.bor(
		bit32.lshift(buffer.readu8(payload, 0), 24),
		bit32.lshift(buffer.readu8(payload, 1), 16),
		bit32.lshift(buffer.readu8(payload, 2), 8),
		buffer.readu8(payload, 3)
	)
	local commitLength = buffer.len(payload) - 4

	-- The server strips the 2-byte MLS ProtocolVersion prefix from the commit bytes before
	-- broadcasting. Prepend it back so processCommit receives a full MLSMessage.
	local framedCommit = buffer.create(2 + commitLength)
	buffer.writeu8(framedCommit, 0, 0x00)
	buffer.writeu8(framedCommit, 1, 0x01)
	buffer.copy(framedCommit, 2, payload, 4, commitLength)

	if self.isPendingCommitter then
		self.isPendingCommitter = false

		self.logger:debug(`committer path: processCommit (transition_id={transitionId})`)

		local commitResult = self.daveSession:processCommit(framedCommit)

		if commitResult:isFailed() then
			self.logger:warn(`own commit rejected by processCommit`)
			commitResult:destroy()
			return nil
		end

		if commitResult:isIgnored() then
			self.logger:debug(`own commit already applied (ignored)`)
			commitResult:destroy()
			return nil
		end

		local rosterIds = commitResult:getRosterMemberIds()
		commitResult:destroy()

		self.logger:info(`own commit applied, roster={#rosterIds} member(s)`)
		self:rotateDaveKeys(rosterIds, userId, ssrc)

		return rosterIds
	end

	self.logger:debug(`commit transition_id={transitionId} commit_data={commitLength}B`)

	local commitResult = self.daveSession:processCommit(framedCommit)

	if commitResult:isFailed() then
		self.logger:warn(`MLS processCommit failed, commit rejected`)
		commitResult:destroy()
		return nil
	elseif commitResult:isIgnored() then
		self.logger:debug(`MLS commit ignored (duplicate or out-of-order)`)
		commitResult:destroy()
		return nil
	end

	local rosterIds = commitResult:getRosterMemberIds()
	commitResult:destroy()

	self.logger:info(`MLS epoch advanced via commit, roster={#rosterIds} member(s)`)

	self:rotateDaveKeys(rosterIds, userId, ssrc)

	return rosterIds
end

--[=[
	@within Voice.DaveManager

	Processes an MLS welcome for clients being added to an existing epoch, then rotates keys for the roster.
]=]
function DaveManager.Prototype.handleWelcome(
	self: DaveManager,
	payload: any,
	userId: string,
	ssrc: number?
): { string }?
	self.logger:info(`received DAVE MLS welcome`)

	if not self.daveSession then
		self.logger:debug(`DaveMlsWelcome: no DAVE session, skipping`)
		return nil
	end

	local transitionId = bit32.bor(
		bit32.lshift(buffer.readu8(payload, 0), 24),
		bit32.lshift(buffer.readu8(payload, 1), 16),
		bit32.lshift(buffer.readu8(payload, 2), 8),
		buffer.readu8(payload, 3)
	)
	local welcomeLength = buffer.len(payload) - 4
	local welcomeData = buffer.create(welcomeLength)
	buffer.copy(welcomeData, 0, payload, 4, welcomeLength)

	self.logger:debug(`welcome transition_id={transitionId} welcome_data={welcomeLength}B`)

	local welcomeResult = self.daveSession:processWelcome(welcomeData, self.recognizedUserIds)

	if not welcomeResult then
		self.logger:warn(`MLS welcome rejected (not intended for our key package), waiting for re-add`)
		return nil
	end

	local rosterIds = welcomeResult:getRosterMemberIds()
	welcomeResult:destroy()

	self.logger:info(`MLS welcome processed, roster={#rosterIds} member(s)`)

	self:rotateDaveKeys(rosterIds, userId, ssrc)

	return rosterIds
end

--[=[
	@within Voice.DaveManager

	Responsible for constructing this class.
]=]
function DaveManager.Interface.new(loggerInstance: logger.Logger): DaveManager
	local self = setmetatable(
		{
			isPendingCommitter = false,
			daveDecryptors = {},
			recognizedUserIds = {},
			ssrcToUserId = {},
			logger = loggerInstance,
		} :: DaveManager,
		{ __index = DaveManager.Prototype }
	)

	if not daveLoggerHasBeenSet then
		daveLoggerHasBeenSet = true
		daveLogger = logger.new("Dave", loggerInstance:getLogLevel())

		dave.setLogSinkCallback(function(severity, message)
			if severity < dave.sys.loggingSeverity.warning then
				return
			end

			daveLogger:warn(if severity >= dave.sys.loggingSeverity.error then `[error] {message}` else message)
		end)
	end

	return self
end

export type DaveManager = typeof(DaveManager.Prototype) & {
	daveSession: dave.Session?,
	pendingDaveProtocolVersion: number?,
	isPendingCommitter: boolean,
	daveEncryptor: dave.Encryptor?,
	daveDecryptors: { [string]: dave.Decryptor },
	recognizedUserIds: { string },
	ssrcToUserId: { [number]: string },
	logger: logger.Logger,
}

return DaveManager.Interface
