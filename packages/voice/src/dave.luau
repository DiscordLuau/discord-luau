--[=[
	@class Voice.DaveManager
	@__index Prototype

	Manages the DAVE (Discord Audio/Video Encryption) MLS session lifecycle for a voice connection.

	Owns the MLS session, encryptor, per-user decryptors, and SSRC-to-user-ID mapping. The owner (Voice.Connection)
	passes it the voice gateway's DAVE opcodes and sets `sendMessage`, through which it answers, `onTransitionExecuted`
	and `onMediaReadyChanged`. libdave objects come from `createSession`, `createEncryptor` and `createDecryptor`, which
	tests replace with stand-ins.
]=]

--[=[
	@prop daveSession dave.Session?
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
	@prop recognizedUserIds { [string]: true }
	@within Voice.DaveManager

	Users connected to the media session: added by op 11, removed by op 13. libdave rejects an add proposal or a
	welcome naming anyone else. It survives a group reset.
]=]

--[=[
	@prop roster { [string]: true }
	@within Voice.DaveManager

	Every member of the MLS group, the bot included, mirrored from the change set each commit or welcome returns.
	Cleared by a group reset.
]=]

--[=[
	@prop pendingTransitions { [number]: number }
	@within Voice.DaveManager

	The protocol version each prepared transition moves to, by transition id, until it executes.
]=]

--[=[
	@prop pendingSelfRatchets { [number]: dave.KeyRatchet }
	@within Voice.DaveManager

	The bot's own key ratchet, held by transition id until that transition executes. There is at most one: a newer
	commit supersedes an older one.
]=]

--[=[
	@prop selfRatchetApplied boolean
	@within Voice.DaveManager

	Whether the encryptor holds a key from the current session. False again after a group reset.
]=]

--[=[
	@prop reinitializing boolean
	@within Voice.DaveManager

	True while recovering from a commit or welcome libdave could not process, so a burst of failures sends one op 31.
	Cleared by the next processed commit or welcome, or an executed transition.
]=]

--[=[
	@prop mediaReady boolean
	@within Voice.DaveManager

	Whether audio can flow: true when media is not under DAVE (`mediaProtocolVersion` 0), or under DAVE once the
	encryptor holds a key from the current session. Never true before Session Description or after `cleanup`.
]=]

--[=[
	@prop ssrcToUserId { [number]: string }
	@within Voice.DaveManager
]=]

--[=[
	@prop protocolVersion number
	@within Voice.DaveManager

	The MLS session's DAVE protocol version: set at Session Description, by a group reset and when a transition
	executes. 0 without a session.
]=]

--[=[
	@prop mediaProtocolVersion number?
	@within Voice.DaveManager

	The DAVE protocol version media is sent and received under: set at Session Description and when a transition
	executes, nil before Session Description and after `cleanup`.
]=]

--[=[
	@prop externalSender buffer?
	@within Voice.DaveManager

	The voice gateway's MLS external sender (op 25), applied to every session a group reset creates.
]=]

--[=[
	@prop channelId string
	@within Voice.DaveManager

	The MLS group id, which is the voice channel's id; set at Session Description.
]=]

--[=[
	@prop userId string
	@within Voice.DaveManager

	The bot's user id; set at Session Description.
]=]

--[=[
	@prop ssrc number?
	@within Voice.DaveManager

	The bot's audio ssrc, which every new encryptor is told is Opus; set at Session Description.
]=]

--[=[
	@prop createSession (authSessionId: string, onMlsFailure: ((source: string, reason: string) -> ())?) -> dave.Session
	@within Voice.DaveManager

	Makes the MLS session; `dave.Session.new` unless a test replaces it.
]=]

--[=[
	@prop createEncryptor () -> dave.Encryptor
	@within Voice.DaveManager

	Makes the encryptor; `dave.Encryptor.new` unless a test replaces it.
]=]

--[=[
	@prop createDecryptor () -> dave.Decryptor
	@within Voice.DaveManager

	Makes a decryptor; `dave.Decryptor.new` unless a test replaces it.
]=]

--[=[
	@prop sendMessage ((message: string | buffer, purpose: string) -> ())?
	@within Voice.DaveManager

	Sends a message to the voice gateway, set by the owner: a string as JSON text, a buffer as a binary frame.
	`purpose` names it in logs.
]=]

--[=[
	@prop onTransitionExecuted ((rosterSize: number) -> ())?
	@within Voice.DaveManager

	Set by the owner; called when a transition executes, with the number of group members, the bot included.
]=]

--[=[
	@prop onMediaReadyChanged ((ready: boolean) -> ())?
	@within Voice.DaveManager

	Set by the owner; called with the new value whenever `mediaReady` changes.
]=]

--[=[
	@prop logger logger.Logger
	@within Voice.DaveManager
]=]

local dave = require("../luau_packages/dave")
local logger = require("../luau_packages/logger")
local apiTypes = require("../luau_packages/api_types")
local stdPolyfills = require("../luau_packages/std_polyfills")

local daveLogger: logger.Logger
local daveLoggerHasBeenSet = false

local DaveManager = {}

DaveManager.Interface = {}
DaveManager.Prototype = {}

local function splitTransitionPayload(payload: buffer): (number, buffer)
	local transitionId = bit32.bor(bit32.lshift(buffer.readu8(payload, 0), 8), buffer.readu8(payload, 1))
	local message = buffer.create(buffer.len(payload) - 2)

	buffer.copy(message, 0, payload, 2)

	return transitionId, message
end

--[=[
	@within Voice.DaveManager

	Destroys the session, the encryptor, every decryptor and every held key ratchet, then resets all DAVE state.
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
	end

	self:destroyPendingSelfRatchets()
	self.daveDecryptors = {}
	self.recognizedUserIds = {}
	self.ssrcToUserId = {}
	self.roster = {}
	self.pendingTransitions = {}
	self.selfRatchetApplied = false
	self.reinitializing = false
	self.externalSender = nil
	self.protocolVersion = 0
	self.mediaProtocolVersion = nil
	self:updateMediaReady()
end

--[=[
	@within Voice.DaveManager

	Starts DAVE for a new voice session from Session Description's `dave_protocol_version`. Version 0 needs nothing
	more; above 0 it creates the MLS session and the encryptor and sends a key package (op 26).
]=]
function DaveManager.Prototype.handleSessionDescription(
	self: DaveManager,
	protocolVersion: number,
	channelId: string,
	userId: string,
	ssrc: number?
)
	self.channelId = channelId
	self.userId = userId
	self.ssrc = ssrc
	self.protocolVersion = protocolVersion
	self.mediaProtocolVersion = protocolVersion
	self.logger:info(`voice session uses DAVE protocol version {protocolVersion}`)

	if protocolVersion > 0 then
		self:resetGroup(protocolVersion)
	end

	self:updateMediaReady()
end

--[=[
	@within Voice.DaveManager
	@private

	Starts the MLS group over at `protocolVersion`. libdave never clears a session's roster, and a session without
	`init` has no key package, so it makes a new session whose MLS failures are logged at warn, initialises it, applies
	the stored external sender, forgets the old group's roster, transitions and held key, replaces the encryptor, and
	sends a key package (op 26) so the voice gateway adds the bot again. Decryptors stay until the next result shows
	who is still in the group.
]=]
function DaveManager.Prototype.resetGroup(self: DaveManager, protocolVersion: number)
	local previousSession = self.daveSession
	local externalSender = self.externalSender
	local session = self.createSession("", function(source: string, reason: string)
		self.logger:warn(`DAVE MLS failure in {source}: {reason}`)
	end)

	if previousSession then
		previousSession:destroy()
	end

	self.daveSession = session
	self.protocolVersion = protocolVersion
	session:init(protocolVersion, self.channelId, self.userId)

	if externalSender then
		session:setExternalSender(externalSender)
	end

	self:destroyPendingSelfRatchets()
	self.roster = {}
	self.pendingTransitions = {}
	self.selfRatchetApplied = false
	self:recreateEncryptor()
	self:updateMediaReady()
	self.logger:info(`DAVE group reset at protocol version {protocolVersion}`)
	self:sendKeyPackage(session)
end

--[=[
	@within Voice.DaveManager
	@private

	Replaces the encryptor with a new one for the bot's ssrc, so no key from an earlier group stays in it.
]=]
function DaveManager.Prototype.recreateEncryptor(self: DaveManager)
	local previousEncryptor = self.daveEncryptor
	local encryptor = self.createEncryptor()
	local ssrc = self.ssrc

	if previousEncryptor then
		previousEncryptor:destroy()
	end

	self.daveEncryptor = encryptor

	if ssrc then
		encryptor:assignSsrcToCodec(ssrc, dave.sys.codec.opus)
	else
		self.logger:warn(`the DAVE encryptor has no ssrc to assign; Ready should have set one`)
	end
end

--[=[
	@within Voice.DaveManager
	@private

	Sends `session`'s key package (op 26). Each call makes libdave replace its join key package, so a group reset is
	the only caller. An empty key package (the session has no MLS leaf node) is not sent.
]=]
function DaveManager.Prototype.sendKeyPackage(self: DaveManager, session: dave.Session)
	local keyPackage = session:getMarshalledKeyPackage()
	local keyPackageLength = buffer.len(keyPackage)

	if keyPackageLength == 0 then
		self.logger:warn(`the DAVE key package is empty, so op 26 is not sent; the voice gateway cannot add the bot`)

		return
	end

	local frame = buffer.create(1 + keyPackageLength)

	buffer.writeu8(frame, 0, apiTypes.voice.opcodes.DaveMlsKeyPackage)
	buffer.copy(frame, 1, keyPackage, 0, keyPackageLength)
	self.logger:debug(`sending the DAVE key package: {keyPackageLength} bytes`)
	self:send(frame, "DAVE key package")
end

--[=[
	@within Voice.DaveManager
	@private

	Sends `message` through `sendMessage`.
]=]
function DaveManager.Prototype.send(self: DaveManager, message: string | buffer, purpose: string)
	local sendMessage = self.sendMessage

	if not sendMessage then
		self.logger:warn(`cannot send the {purpose}: the owner has not set sendMessage`)

		return
	end

	sendMessage(message, purpose)
end

--[=[
	@within Voice.DaveManager

	Adds users who connected to the media session (op 11) to the recognized set.
]=]
function DaveManager.Prototype.handleClientsConnect(self: DaveManager, userIds: { string })
	for _, userId in userIds do
		self.recognizedUserIds[userId] = true
	end
end

--[=[
	@within Voice.DaveManager

	Forgets a user who left the media session (op 13): they are no longer recognized, and their decryptor is destroyed.
]=]
function DaveManager.Prototype.handleClientDisconnect(self: DaveManager, userId: string)
	local decryptor = self.daveDecryptors[userId]

	self.recognizedUserIds[userId] = nil

	if decryptor then
		self.logger:debug(`destroying the DAVE decryptor of disconnected user={userId}`)
		decryptor:destroy()
		self.daveDecryptors[userId] = nil
	end
end

--[=[
	@within Voice.DaveManager

	Handles prepare transition (op 21): records the protocol version the transition moves to, which applies only when
	it executes. A move to version 0 lets every decryptor accept plain frames now, because senders may switch first. A
	payload without a numeric transition id and protocol version is ignored.
]=]
function DaveManager.Prototype.handlePrepareTransition(self: DaveManager, payload: any)
	local transitionId = tonumber(payload.transition_id)
	local protocolVersion = tonumber(payload.protocol_version)

	if not transitionId or not protocolVersion then
		self.logger:warn(
			`ignoring a DAVE prepare transition with transition id {payload.transition_id} and protocol version {payload.protocol_version}: both must be numbers`
		)

		return
	end

	self.logger:info(`DAVE prepare transition {transitionId} to protocol version {protocolVersion}`)
	self.pendingTransitions[transitionId] = protocolVersion

	if protocolVersion == 0 then
		for _, decryptor in self.daveDecryptors do
			decryptor:transitionToPassthroughMode(true)
		end
	end

	self:acknowledgeTransition(transitionId)
end

--[=[
	@within Voice.DaveManager

	Handles execute transition (op 22) for a transition this client recorded; any other transition id is ignored, and a
	non-numeric one is warned.
]=]
function DaveManager.Prototype.handleExecuteTransition(self: DaveManager, payload: any)
	local transitionId = tonumber(payload.transition_id)

	if not transitionId then
		self.logger:warn(
			`ignoring a DAVE execute transition with transition id {payload.transition_id}: it must be a number`
		)

		return
	end

	if not self.pendingTransitions[transitionId] then
		self.logger:debug(`ignoring DAVE execute transition {transitionId}: no such transition is pending`)

		return
	end

	self:executeTransition(transitionId)
end

--[=[
	@within Voice.DaveManager

	Whether a transition to protocol version 0 is prepared and not executed yet. Senders may already send plain frames
	then, so the receive side accepts them.
]=]
function DaveManager.Prototype.hasPendingDowngrade(self: DaveManager): boolean
	local downgradePending = false

	for _, protocolVersion in self.pendingTransitions do
		downgradePending = downgradePending or protocolVersion == 0
	end

	return downgradePending
end

--[=[
	@within Voice.DaveManager

	Handles prepare epoch (op 24). Epoch 1 means the voice gateway is creating the group again, so the group is reset
	at the payload's protocol version, which sends a new key package. Without a numeric version in the payload it
	falls back to the session's version, and without a version above 0 it keeps the group. Any other epoch keeps the
	group.
]=]
function DaveManager.Prototype.handlePrepareEpoch(self: DaveManager, payload: any)
	local epoch = tonumber(payload.epoch)
	local payloadVersion = tonumber(payload.protocol_version)
	local protocolVersion = payloadVersion or self.protocolVersion

	if epoch ~= 1 then
		self.logger:debug(`DAVE prepare epoch {tostring(payload.epoch)} keeps the group`)

		return
	end

	if not self.mediaProtocolVersion then
		self.logger:warn(`ignoring a DAVE prepare epoch that arrived before Session Description`)

		return
	end

	if protocolVersion <= 0 then
		self.logger:warn(
			`ignoring a DAVE prepare epoch 1 with protocol version {tostring(payload.protocol_version)}: no version above 0 to reset the group at`
		)

		return
	end

	if not payloadVersion then
		self.logger:warn(
			`DAVE prepare epoch 1 carried protocol version {tostring(payload.protocol_version)}; using the session's protocol version {protocolVersion}`
		)
	end

	self.logger:info(`DAVE prepare epoch 1: resetting the group at protocol version {protocolVersion}`)
	self:resetGroup(protocolVersion)
end

--[=[
	@within Voice.DaveManager

	Stores the voice gateway's MLS external sender (op 25) and applies it to the current session; a group reset applies
	it to the session it creates. Sends nothing: the key package goes out when a session is created.
]=]
function DaveManager.Prototype.handleExternalSender(self: DaveManager, payload: buffer)
	local session = self.daveSession

	self.externalSender = payload
	self.logger:info(`received the DAVE MLS external sender: {buffer.len(payload)} bytes`)

	if session then
		session:setExternalSender(payload)
	else
		self.logger:debug(`no DAVE session yet; the next one gets the external sender`)
	end
end

--[=[
	@within Voice.DaveManager

	Processes MLS proposals (op 27) against the recognized users and the bot, and sends the resulting commit and welcome
	(op 28). Sending a commit is not a transition: that arrives with the announced commit (op 29).
]=]
function DaveManager.Prototype.handleProposals(self: DaveManager, payload: buffer)
	local session = self.daveSession

	if not session then
		self.logger:warn(`ignoring DAVE MLS proposals: there is no DAVE session`)

		return
	end

	local commitWelcome = session:processProposals(payload, self:recognizedWithSelf())

	if not commitWelcome then
		self.logger:debug(`DAVE MLS proposals left nothing to commit`)

		return
	end

	local commitWelcomeLength = buffer.len(commitWelcome)
	local frame = buffer.create(1 + commitWelcomeLength)

	buffer.writeu8(frame, 0, apiTypes.voice.opcodes.DaveMlsCommitWelcome)
	buffer.copy(frame, 1, commitWelcome, 0, commitWelcomeLength)
	self.logger:debug(`sending the DAVE MLS commit and welcome: {commitWelcomeLength} bytes`)
	self:send(frame, "DAVE commit and welcome")
end

--[=[
	@within Voice.DaveManager

	Processes an announced MLS commit (op 29), which starts with a two-byte transition id. A processed commit updates the
	roster and keys and readies its transition; an ignored one changes nothing; a failed one starts a recovery.
]=]
function DaveManager.Prototype.handleCommitTransition(self: DaveManager, payload: buffer)
	local session = self.daveSession
	local transitionId, commit = splitTransitionPayload(payload)

	if not session then
		self.logger:debug(`ignoring the DAVE commit for transition {transitionId}: there is no DAVE session`)

		return
	end

	local result = session:processCommit(commit)

	if result:isFailed() then
		result:destroy()
		self.logger:warn(`the DAVE commit for transition {transitionId} failed`)
		self:recoverFromInvalidTransition(transitionId)

		return
	end

	if result:isIgnored() then
		result:destroy()
		self.logger:debug(`the DAVE commit for transition {transitionId} was ignored`)

		return
	end

	self:applyRoster(result)
	result:destroy()
	self.logger:info(`processed the DAVE commit for transition {transitionId}`)
	self:completeTransition(session, transitionId)
end

--[=[
	@within Voice.DaveManager

	Processes an MLS welcome (op 30), which starts with a two-byte transition id, against the recognized users and the
	bot: libdave checks every member of the welcomed group. A processed welcome updates the roster and keys and readies
	its transition; a rejected one starts a recovery.
]=]
function DaveManager.Prototype.handleWelcome(self: DaveManager, payload: buffer)
	local session = self.daveSession
	local transitionId, welcome = splitTransitionPayload(payload)

	if not session then
		self.logger:debug(`ignoring the DAVE welcome for transition {transitionId}: there is no DAVE session`)

		return
	end

	local result = session:processWelcome(welcome, self:recognizedWithSelf())

	if not result then
		self.logger:warn(`the DAVE welcome for transition {transitionId} was rejected`)
		self:recoverFromInvalidTransition(transitionId)

		return
	end

	self:applyRoster(result)
	result:destroy()
	self.logger:info(`processed the DAVE welcome for transition {transitionId}`)
	self:completeTransition(session, transitionId)
end

--[=[
	@within Voice.DaveManager
	@private

	Answers a commit or welcome libdave could not process: tells the voice gateway (op 31) and resets the group, which
	sends a new key package so the gateway can add the bot again. While a recovery is under way, further failures are
	skipped: a burst sends one op 31, and the key package a welcome may already be on its way for is not replaced.
]=]
function DaveManager.Prototype.recoverFromInvalidTransition(self: DaveManager, transitionId: number)
	if self.reinitializing then
		self.logger:debug(`already recovering the DAVE group, so transition {transitionId} gets no op 31`)

		return
	end

	self.reinitializing = true
	self:send(
		stdPolyfills.serde.encode("json" :: any, {
			op = apiTypes.voice.opcodes.DaveMlsInvalidCommitWelcome,
			d = { transition_id = transitionId },
		}),
		"DAVE invalid commit or welcome"
	)
	self:resetGroup(self.protocolVersion)
end

--[=[
	@within Voice.DaveManager
	@private

	Applies a commit or welcome result to `roster`. libdave returns only what changed: an id with a signature joined
	or changed keys, and an id without one left. Only ids from this result are queried, because libdave aborts the
	process on any other. Then every decryptor whose user is not in the roster is destroyed.
]=]
function DaveManager.Prototype.applyRoster(self: DaveManager, result: RosterResult)
	local remainingDecryptors: { [string]: dave.Decryptor } = {}

	for _, memberId in result:getRosterMemberIds() do
		if buffer.len(result:getRosterMemberSignature(memberId)) > 0 then
			self.roster[memberId] = true
		else
			self.roster[memberId] = nil
		end
	end

	for userId, decryptor in self.daveDecryptors do
		if self.roster[userId] then
			remainingDecryptors[userId] = decryptor
		else
			self.logger:debug(`destroying the DAVE decryptor of user={userId}, who is not in the group`)
			decryptor:destroy()
		end
	end

	self.daveDecryptors = remainingDecryptors
end

--[=[
	@within Voice.DaveManager
	@private

	Finishes a processed commit or welcome: the bot's own key is held until the transition executes, every other
	member's decryptor gets its key for the new epoch, and the transition is recorded at the session's protocol
	version. The bot's key is held first, so a member whose decryptor fails cannot leak it.
]=]
function DaveManager.Prototype.completeTransition(self: DaveManager, session: dave.Session, transitionId: number)
	local selfRatchet = session:getKeyRatchet(self.userId)

	self.reinitializing = false

	if selfRatchet then
		self:destroyPendingSelfRatchets()
		self.pendingSelfRatchets[transitionId] = selfRatchet
	else
		self.logger:debug(`no DAVE key ratchet for the bot: the session has no group`)
	end

	for memberId in self.roster do
		if memberId ~= self.userId then
			self:giveRatchet(session, memberId)
		end
	end

	self.pendingTransitions[transitionId] = self.protocolVersion
	self:acknowledgeTransition(transitionId)
end

--[=[
	@within Voice.DaveManager
	@private

	Gives `memberId`'s decryptor, created if missing, their key for the new epoch, then destroys the ratchet: libdave
	copies it.
]=]
function DaveManager.Prototype.giveRatchet(self: DaveManager, session: dave.Session, memberId: string)
	local ratchet = session:getKeyRatchet(memberId)

	if not ratchet then
		self.logger:debug(`no DAVE key ratchet for user={memberId}: the session has no group`)

		return
	end

	local decryptor = self.daveDecryptors[memberId] or self:createMemberDecryptor(memberId)

	decryptor:transitionToKeyRatchet(ratchet)
	ratchet:destroy()
end

--[=[
	@within Voice.DaveManager
	@private

	Creates `userId`'s decryptor. While media is not under DAVE (protocol version 0) it accepts plain frames.
]=]
function DaveManager.Prototype.createMemberDecryptor(self: DaveManager, userId: string): dave.Decryptor
	local decryptor = self.createDecryptor()

	if self.mediaProtocolVersion == 0 then
		decryptor:transitionToPassthroughMode(true)
	end

	self.daveDecryptors[userId] = decryptor
	self.logger:debug(`created the DAVE decryptor of user={userId}`)

	return decryptor
end

--[=[
	@within Voice.DaveManager
	@private

	Destroys every held key ratchet of the bot's.
]=]
function DaveManager.Prototype.destroyPendingSelfRatchets(self: DaveManager)
	for transitionId, ratchet in self.pendingSelfRatchets do
		self.logger:debug(`dropping the bot's DAVE key ratchet held for transition {transitionId}`)
		ratchet:destroy()
	end

	self.pendingSelfRatchets = {}
end

--[=[
	@within Voice.DaveManager
	@private

	Executes transition 0 at once, since the voice gateway waits for nobody on it, and tells the voice gateway this
	client is ready for any other (op 23).
]=]
function DaveManager.Prototype.acknowledgeTransition(self: DaveManager, transitionId: number)
	if transitionId == 0 then
		self:executeTransition(transitionId)
	else
		self:send(
			stdPolyfills.serde.encode("json" :: any, {
				op = apiTypes.voice.opcodes.DaveProtocolTransitionReady,
				d = { transition_id = transitionId },
			}),
			"DAVE transition ready"
		)
	end
end

--[=[
	@within Voice.DaveManager
	@private

	Executes a recorded transition, taking the bot's key held for it either way. To version 0 the encryptor passes
	frames through and the held key is destroyed unused. To a DAVE version the held key goes to the encryptor, and
	passthrough ends on both sides, key or not; decryptors still accept plain frames for 10 seconds. Then both
	versions move to the transition's, media readiness is updated, and the epoch callback gets the roster size, in that
	order, so a send from an epoch listener sees the new readiness.
]=]
function DaveManager.Prototype.executeTransition(self: DaveManager, transitionId: number)
	local protocolVersion = self.pendingTransitions[transitionId]
	local selfRatchet = self.pendingSelfRatchets[transitionId]
	local encryptor = self.daveEncryptor
	local session = self.daveSession
	local onTransitionExecuted = self.onTransitionExecuted

	self.pendingTransitions[transitionId] = nil
	self.pendingSelfRatchets[transitionId] = nil

	if protocolVersion > 0 then
		self:applySelfRatchet(transitionId, selfRatchet)

		for _, decryptor in self.daveDecryptors do
			decryptor:transitionToPassthroughMode(false)
		end
	elseif selfRatchet then
		self.logger:debug(`dropping the bot's DAVE key ratchet for transition {transitionId}: it moves to version 0`)
		selfRatchet:destroy()
	end

	if encryptor then
		encryptor:setPassthroughMode(protocolVersion == 0)
	end

	if session then
		session:setProtocolVersion(protocolVersion)
	end

	self.protocolVersion = protocolVersion
	self.mediaProtocolVersion = protocolVersion
	self.reinitializing = false
	self.logger:info(`DAVE transition {transitionId} executed at protocol version {protocolVersion}`)
	self:updateMediaReady()

	if onTransitionExecuted then
		onTransitionExecuted(self:rosterSize())
	end
end

--[=[
	@within Voice.DaveManager
	@private

	Gives the encryptor `ratchet`, the bot's key taken for `transitionId`, then destroys it. The encryptor gets one key
	per epoch, because setting a key resets its nonce. Without a key (a newer commit superseded it, or there is no
	group) the encryptor keeps what it has; without an encryptor the key is destroyed unused.
]=]
function DaveManager.Prototype.applySelfRatchet(self: DaveManager, transitionId: number, ratchet: dave.KeyRatchet?)
	local encryptor = self.daveEncryptor

	if not ratchet then
		self.logger:debug(`DAVE transition {transitionId} executes without a new key for the bot`)

		return
	end

	if not encryptor then
		self.logger:debug(`dropping the bot's DAVE key ratchet for transition {transitionId}: there is no encryptor`)
		ratchet:destroy()

		return
	end

	encryptor:setKeyRatchet(ratchet)
	ratchet:destroy()
	self.selfRatchetApplied = true
end

--[=[
	@within Voice.DaveManager
	@private

	Recomputes `mediaReady` from `mediaProtocolVersion` and `selfRatchetApplied`, and calls `onMediaReadyChanged` when
	it changes.
]=]
function DaveManager.Prototype.updateMediaReady(self: DaveManager)
	local protocolVersion = self.mediaProtocolVersion
	local ready = if protocolVersion then protocolVersion == 0 or self.selfRatchetApplied else false
	local onMediaReadyChanged = self.onMediaReadyChanged

	if ready ~= self.mediaReady then
		self.mediaReady = ready
		self.logger:info(`DAVE media {if ready then "can flow" else "waits for the group key"}`)

		if onMediaReadyChanged then
			onMediaReadyChanged(ready)
		end
	end
end

--[=[
	@within Voice.DaveManager
	@private

	The recognized users and the bot, as the list libdave takes.
]=]
function DaveManager.Prototype.recognizedWithSelf(self: DaveManager): { string }
	local userIds = { self.userId }

	for userId in self.recognizedUserIds do
		if userId ~= self.userId then
			table.insert(userIds, userId)
		end
	end

	return userIds
end

--[=[
	@within Voice.DaveManager
	@private

	The number of group members. The bot always counts itself, so this is at least 1 even without a group.
]=]
function DaveManager.Prototype.rosterSize(self: DaveManager): number
	local size = if self.roster[self.userId] then 0 else 1

	for _ in self.roster do
		size += 1
	end

	return size
end

--[=[
	@within Voice.DaveManager

	Responsible for constructing this class.
]=]
function DaveManager.Interface.new(loggerInstance: logger.Logger): DaveManager
	local self = setmetatable(
		{
			daveDecryptors = {},
			recognizedUserIds = {},
			roster = {},
			pendingTransitions = {},
			pendingSelfRatchets = {},
			selfRatchetApplied = false,
			reinitializing = false,
			mediaReady = false,
			ssrcToUserId = {},
			protocolVersion = 0,
			channelId = "",
			userId = "",
			createSession = dave.Session.new,
			createEncryptor = dave.Encryptor.new,
			createDecryptor = dave.Decryptor.new,
			logger = loggerInstance,
		} :: DaveManager,
		{ __index = DaveManager.Prototype }
	)

	if not daveLoggerHasBeenSet then
		daveLoggerHasBeenSet = true
		daveLogger = logger.new("Dave", loggerInstance:getLogLevel())

		dave.setLogSinkCallback(function(severity, message)
			if severity < dave.sys.loggingSeverity.warning then
				daveLogger:debug(message)
			elseif severity < dave.sys.loggingSeverity.error then
				daveLogger:warn(message)
			else
				daveLogger:warn(`[error] {message}`)
			end
		end)
	end

	return self
end

type RosterResult = {
	getRosterMemberIds: (self: any) -> { string },
	getRosterMemberSignature: (self: any, rosterId: string) -> buffer,
}

export type DaveManager = typeof(DaveManager.Prototype) & {
	daveSession: dave.Session?,
	daveEncryptor: dave.Encryptor?,
	daveDecryptors: { [string]: dave.Decryptor },
	recognizedUserIds: { [string]: true },
	roster: { [string]: true },
	pendingTransitions: { [number]: number },
	pendingSelfRatchets: { [number]: dave.KeyRatchet },
	selfRatchetApplied: boolean,
	reinitializing: boolean,
	mediaReady: boolean,
	ssrcToUserId: { [number]: string },
	protocolVersion: number,
	mediaProtocolVersion: number?,
	externalSender: buffer?,
	channelId: string,
	userId: string,
	ssrc: number?,
	createSession: (authSessionId: string, onMlsFailure: ((source: string, reason: string) -> ())?) -> dave.Session,
	createEncryptor: () -> dave.Encryptor,
	createDecryptor: () -> dave.Decryptor,
	sendMessage: ((message: string | buffer, purpose: string) -> ())?,
	onTransitionExecuted: ((rosterSize: number) -> ())?,
	onMediaReadyChanged: ((ready: boolean) -> ())?,
	logger: logger.Logger,
}

return DaveManager.Interface
