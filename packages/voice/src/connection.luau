local stdPolyfills = require("../luau_packages/std_polyfills")

local emitter = require("../luau_packages/emitter")
local future = require("../luau_packages/future")
local logger = require("../luau_packages/logger")
local secret = require("../luau_packages/secret")
local websocket = require("../luau_packages/websocket")
local apiTypes = require("../luau_packages/api_types")
local dave = require("../luau_packages/dave")
local sodium = require("../luau_packages/sodium")

local voiceWebsocket = require("./websocket")
local voiceUdp = require("./udp")
local voiceRtpCrypto = require("./rtp")
local voiceDaveManager = require("./dave")
local voiceJitter = require("./jitter")

local ENCRYPTION_MODE_AES256_GCM = "aead_aes256_gcm_rtpsize"
local ENCRYPTION_MODE_XCHACHA20 = "aead_xchacha20_poly1305_rtpsize"

local JOIN_TIMEOUT_SECONDS = 15
local DISCONNECT_GRACE_SECONDS = 5
local STABLE_SECONDS = 60
local SHARD_POLL_SECONDS = 0.5
local MAX_RECONNECT_ATTEMPTS = 5
local MAX_RECONNECT_DELAY_SECONDS = 16
local SECRET_KEY_SIZE = 32

local NO_CLOSE_CODE = -1
local NORMAL_CLOSE_CODE = 1000
local GOING_AWAY_CLOSE_CODE = 1001
local ABNORMAL_CLOSE_CODE = 1006
local INTERNAL_ERROR_CLOSE_CODE = 1011

local LEAVE_PAYLOAD_FORMAT = '{"op":%d,"d":{"guild_id":"%s","channel_id":null,"self_mute":false,"self_deaf":false}}'

local RESUMABLE_CLOSE_CODES = {
	[NO_CLOSE_CODE] = true,
	[GOING_AWAY_CLOSE_CODE] = true,
	[ABNORMAL_CLOSE_CODE] = true,
	[apiTypes.voice.closeCodes.VoiceServerCrashed] = true,
}

local GRACE_CLOSE_CODES = {
	[apiTypes.voice.closeCodes.Disconnected] = true,
	[apiTypes.voice.closeCodes.DisconnectedCallTerminated] = true,
}

local FATAL_CLOSE_MEANINGS = {
	[apiTypes.voice.closeCodes.UnknownOpcode] = "the voice gateway did not recognise an opcode",
	[apiTypes.voice.closeCodes.FailedToDecodePayload] = "the voice gateway could not decode a payload",
	[apiTypes.voice.closeCodes.NotAuthenticated] = "a payload was sent before Identify",
	[apiTypes.voice.closeCodes.AuthenticationFailed] = "the voice token was rejected",
	[apiTypes.voice.closeCodes.AlreadyAuthenticated] = "Identify was sent twice",
	[apiTypes.voice.closeCodes.ServerNotFound] = "the voice server was not found",
	[apiTypes.voice.closeCodes.UnknownProtocol] = "the voice gateway did not recognise the protocol",
	[apiTypes.voice.closeCodes.UnknownEncryptionMode] = "the voice gateway did not recognise the encryption mode",
	[apiTypes.voice.closeCodes.DaveProtocolRequired] = "the channel requires DAVE end-to-end encryption",
	[apiTypes.voice.closeCodes.BadRequest] = "the voice gateway rejected a malformed request",
	[apiTypes.voice.closeCodes.DisconnectedRateLimited] = "the bot was rate limited",
}

--[=[
	@class Voice.Connection
	@__index Prototype

	Coordinates a full Discord voice connection. Owns four sub-components:

	- `webSocket` - WebSocket lifecycle and heartbeating
	- `udp` - UDP socket, keepalive, and RTP audio send/receive
	- `rtp` - RTP encryption and sequence/timestamp/nonce counters
	- `dave` - DAVE E2EE MLS session and per-user key rotation

	`joinAsync` starts a supervisor thread that owns every lifecycle decision: it sends op 4, waits for Discord's
	VOICE_STATE_UPDATE and VOICE_SERVER_UPDATE, connects, follows moves and server changes, resumes or rejoins after
	drops, and closes for good on a kick, a leave, a fatal close code or exhausted attempts, firing `onClosed`.
	Gateway events, socket closes and timers only record facts and wake it.

	The gateway needs the `GuildVoiceStates` intent; without it Discord never sends the bot its own voice state, so a
	join fails at its timeout with `VOICE_SERVER_UPDATE arrived but no VOICE_STATE_UPDATE; the gateway needs the
	GuildVoiceStates intent`. Classes' `channel:joinAsync` checks the intent and fails at once instead.

	Consumer-facing events: `onReady`, `onResumed`, `onClosed`, `onSpeaking`, `onClientConnect`,
	`onClientDisconnect`, `onDaveEpochTransition`, `onMediaReady`, `onRawAudioFrame`, `onAudioFrame`.

	With DAVE, a ready connection may not carry audio yet: `dave.mediaReady` says whether it can, `onMediaReady` fires
	when it starts to, and `awaitMediaReadyAsync` waits for it.
]=]

--[=[
	@prop webSocket voiceWebsocket.WebSocketTransport
	@within Voice.Connection
]=]

--[=[
	@prop udp voiceUdp.UdpTransport
	@within Voice.Connection
]=]

--[=[
	@prop rtp voiceRtpCrypto.RtpCrypto
	@within Voice.Connection
]=]

--[=[
	@prop dave voiceDaveManager.DaveManager
	@within Voice.Connection
]=]

--[=[
	@prop jitters { [number]: voiceJitter.Jitter }
	@within Voice.Connection
]=]

--[=[
	@prop shard websocket.Shard
	@within Voice.Connection
]=]

--[=[
	@prop guildId string
	@within Voice.Connection
]=]

--[=[
	@prop channelId string
	@within Voice.Connection
]=]

--[=[
	@prop userId string
	@within Voice.Connection
]=]

--[=[
	@prop sessionId string
	@within Voice.Connection

	The voice session id from the bot's VOICE_STATE_UPDATE for this channel, empty until it arrives.
]=]

--[=[
	@prop token secret.Secret<string>
	@within Voice.Connection
]=]

--[=[
	@prop endpoint string
	@within Voice.Connection
]=]

--[=[
	@prop onConnected emitter.Emitter<()>
	@within Voice.Connection
]=]

--[=[
	@prop onDisconnected emitter.Emitter<number?, boolean?>
	@within Voice.Connection
]=]

--[=[
	@prop onReady emitter.Emitter<()>
	@within Voice.Connection

	Fires once for each new session (the first join, a rejoin, a move or a server change) after `status` becomes
	`ready`; a resume fires `onResumed` instead. Every transition into `ready` fires one of the two.
]=]

--[=[
	@prop onHeartbeat emitter.Emitter<number?>
	@within Voice.Connection
]=]

--[=[
	@prop onRawMessage emitter.Emitter<apiTypes.Payload<unknown>>
	@within Voice.Connection
]=]

--[=[
	@prop onSpeaking emitter.Emitter<{ userId: string, ssrc: number, speaking: number }>
	@within Voice.Connection
]=]

--[=[
	@prop onClientConnect emitter.Emitter<{ userId: string }>
	@within Voice.Connection
]=]

--[=[
	@prop onClientDisconnect emitter.Emitter<{ userId: string }>
	@within Voice.Connection
]=]

--[=[
	@prop onDaveEpochTransition emitter.Emitter<number>
	@within Voice.Connection

	Fires when a DAVE transition executes (op 22, or at once for transition 0) with the number of MLS group members,
	the bot included. After a group reset with nobody else in the channel that is 1. `dave.mediaReady` already has
	the transition's value when it fires.
]=]

--[=[
	@prop onMediaReady emitter.Emitter<()>
	@within Voice.Connection

	Fires when audio can start to flow: at Session Description without DAVE, and with DAVE once the bot holds the
	group's key (the transition that added it executed). Fires again after a group reset or reconnect once audio can
	flow again; `dave.mediaReady` has the current value.
]=]

--[=[
	@prop onRawAudioFrame emitter.Emitter<{ userId: string?, ssrc: number, frame: buffer }>
	@within Voice.Connection

	Fires with the Opus payload, the RTP header removed and every encryption layer (DAVE and the RTP cipher) already
	undone, once for each packet the jitter buffer plays, in sequence order and at its pace; lost and late packets are
	skipped. Wire-level ciphertext is never exposed.
]=]

--[=[
	@prop onAudioFrame emitter.Emitter<{ userId: string?, ssrc: number, frame: buffer }>
	@within Voice.Connection

	Fires with decoded stereo s16le 48 kHz PCM for one jitter slot (20 ms for 20 ms senders), loss concealment
	included. It stops about 100 ms after the speaker stops, and does not fire while `decodeAudio` is false.
]=]

--[=[
	@prop decodeAudio boolean
	@within Voice.Connection

	Whether received audio is decoded to PCM; true by default. While it is false the jitter buffers skip Opus decoding,
	loss concealment included, and `onAudioFrame` never fires, while `onRawAudioFrame` still does. A bot that only
	needs raw frames or speaking time sets it to save the decoding work. Each jitter slot reads it, so a change takes
	effect at once, and a decoder that sat idle is replaced before decoding resumes.
]=]

--[=[
	@prop logger logger.Logger
	@within Voice.Connection
]=]

--[=[
	@prop status Status
	@within Voice.Connection

	Where the connection is in its lifecycle: `idle`, `signalling`, `connecting`, `ready`, `resuming`, `disconnected`
	or `closed`.
]=]

--[=[
	@prop generation number
	@within Voice.Connection

	Bumped by every connect and by closing; a socket or op 4 that finishes for an older generation is discarded.
]=]

--[=[
	@prop closeReason CloseReason?
	@within Voice.Connection

	Why the connection closed, nil until it has.
]=]

--[=[
	@prop closeDetail string
	@within Voice.Connection

	A sentence saying why the connection closed, empty until it has.
]=]

--[=[
	@prop onClosed emitter.Emitter<CloseReason, number?>
	@within Voice.Connection

	Fires once when the connection closes for good, with the reason and the close code when there is one.
]=]

--[=[
	@prop onResumed emitter.Emitter<()>
	@within Voice.Connection

	Fires when a dropped voice session is resumed. `onReady` fires instead when a new session becomes ready (the
	first join, a rejoin, a move or a server change), once per connect.
]=]

--[=[
	@prop onWake emitter.Emitter<()>
	@within Voice.Connection
	@private

	Wakes the supervisor and `joinAsync` waiters after a fact is recorded, a timer expires or the status changes.
]=]

--[=[
	@prop recoveryAttempts number
	@within Voice.Connection
	@private

	Resume and rejoin attempts since the connection was last stable for 60 seconds.
]=]

--[=[
	@prop lastFailure string
	@within Voice.Connection
	@private

	Why the latest join, connect or rejoin attempt failed.
]=]

local Connection = {}

Connection.Interface = {}
Connection.Prototype = {}

local function stopTimer(timer: Timer?)
	local thread = if timer then timer.thread else nil

	if thread and coroutine.status(thread) == "suspended" then
		stdPolyfills.task.cancel(thread)
	end
end

--[=[
	@within Voice.Connection
	@private

	Tears down all session state: DAVE, UDP, all jitter buffers, and RTP counters.
]=]
function Connection.Prototype.cleanupSession(self: Connection)
	self.dave:cleanup()
	self.udp:cleanup()
	self.rtp:reset()

	for _, jitter in self.jitters do
		jitter:destroy()
	end

	self.jitters = {}

	self.logger:debug(`session state cleared`)
end

--[=[
	@within Voice.Connection

	Sends a raw message to the voice gateway WebSocket.
]=]
function Connection.Prototype.sendAsync(self: Connection, data: string | buffer)
	return self.webSocket:sendAsync(data)
end

--[=[
	@within Voice.Connection

	Opens the voice WebSocket to `endpoint`. This is a low-level call: `joinAsync` connects on its own. Fails when a
	socket is already open or opening. Session state is preserved when resuming.
]=]
function Connection.Prototype.connectAsync(self: Connection)
	return future.Future.new(function()
		assert(
			not self.webSocket.socketActive and not self.webSocket.socketOpening,
			`Voice connection is already active.`
		)

		if not self.webSocket.isResuming then
			self:cleanupSession()
		end

		self:openVoiceSocket(self.generation)
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Voice.Connection
	@private

	Opens the voice WebSocket to `endpoint`, closing it at once if the connection moved past `generation` during the
	handshake.
]=]
function Connection.Prototype.openVoiceSocket(self: Connection, generation: number)
	local url = self.endpoint

	if not string.find(url, "://", 1, true) then
		url = `wss://{url}`
	end

	if not string.find(url, "%?v=") then
		url = `{url}/?v=8`
	end

	self.logger:info(`connecting to voice WebSocket: {url}`)

	self.webSocket:openSocket(url, function()
		return self.generation == generation and self.status ~= "closed"
	end)
end

--[=[
	@within Voice.Connection

	Closes the voice WebSocket at once. The supervisor treats this as a drop and recovers per the close code (1000
	rejoins). To end the connection, use `leaveAsync` or `destroy`.
]=]
function Connection.Prototype.forceClose(self: Connection, code: number?)
	self.logger:info(`voice force close: {code or NORMAL_CLOSE_CODE}`)
	self.webSocket:forceClose(code)
	self:recordDrop("closed", code or NORMAL_CLOSE_CODE)
end

--[=[
	@within Voice.Connection

	Closes the connection for good, closing the socket with `code` (1000 by default), and asks Discord to take the
	bot out of the channel without waiting for the answer.
]=]
function Connection.Prototype.disconnectAsync(self: Connection, code: number?)
	return future.Future.new(function()
		self:close("left", code, "the voice connection was disconnected")
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Voice.Connection

	Closes the connection for good and asks Discord to take the bot out of the channel without waiting for the answer.
	Synchronous, so it is safe in a signal handler.
]=]
function Connection.Prototype.destroy(self: Connection)
	self:close("left", nil, "the voice connection was destroyed")
end

--[=[
	@within Voice.Connection

	Joins the channel and resolves once the connection is ready. The first call starts the supervisor, which sends
	op 4 and gives up after `timeoutSeconds` (15 by default), closing the connection with `joinTimedOut`. A later call
	sends nothing, waits for the connection to be ready, and its own timeout fails only that call. Fails at once on a
	closed connection.
]=]
function Connection.Prototype.joinAsync(self: Connection, timeoutSeconds: number?)
	return future.Future.new(function()
		local seconds = timeoutSeconds or JOIN_TIMEOUT_SECONDS

		assert(self.status ~= "closed", `voice connection is closed: {self.closeDetail}`)

		if self.status == "ready" then
			self.logger:debug(`joinAsync on a ready voice connection resolves at once`)
		elseif self.status == "idle" then
			self:startSupervisor(seconds)

			local joined, failure = self:awaitReady(seconds, nil)

			if not joined and not self.closeReason then
				self:close("joinTimedOut", nil, failure :: string)
			end

			assert(joined, failure)
		else
			local joined, failure = self:awaitReady(seconds, nil)

			assert(joined, failure)
		end
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Voice.Connection

	Resolves once audio can flow (`dave.mediaReady`), at once if it already can. Fails with `timed out waiting for DAVE
	media readiness` after `timeoutSeconds` (no limit when nil), or with `voice connection closed: <closeDetail>` when
	the connection closes first. Call it after `joinAsync`.
]=]
function Connection.Prototype.awaitMediaReadyAsync(self: Connection, timeoutSeconds: number?)
	return future.Future.new(function()
		local timer = if timeoutSeconds then self:startTimer(timeoutSeconds) else nil

		while not self.dave.mediaReady and self.status ~= "closed" and not (timer and timer.expired) do
			self.onWake:wait()
		end

		stopTimer(timer)

		if not self.dave.mediaReady then
			assert(self.status ~= "closed", `voice connection closed: {self.closeDetail}`)
			error(`timed out waiting for DAVE media readiness`, 0)
		end
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Voice.Connection

	The old name of `joinAsync`, kept for existing callers.
]=]
function Connection.Prototype.requestVoiceAsync(self: Connection)
	return self:joinAsync()
end

--[=[
	@within Voice.Connection

	Asks Discord to take the bot out of the channel (op 4 with a null channel), then closes the connection with
	`left`. A no-op on a closed connection.
]=]
function Connection.Prototype.leaveAsync(self: Connection)
	return future.Future.new(function()
		if self.status == "closed" then
			self.logger:debug(`leaveAsync on a closed voice connection does nothing`)

			return
		end

		local sent = self:sendVoiceStateAsync(nil):await()

		if sent:isErr() then
			self.logger:warn(`voice leave failed to send: {sent:unwrapErr()}`)
		end

		self:close("left", nil, "left the voice channel", true)
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Voice.Connection

	Drops the current voice socket and rejoins, resolving once the connection is ready again. Fails when the
	connection was never joined or closes instead.
]=]
function Connection.Prototype.reconnectAsync(self: Connection)
	return future.Future.new(function()
		local generation = self.generation

		assert(self.status ~= "idle", `voice connection was never joined`)
		assert(self.status ~= "closed", `voice connection is closed: {self.closeDetail}`)

		self:recordDrop("reconnectRequested")

		local reconnected, failure = self:awaitReady(nil, generation)

		assert(reconnected, failure)
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Voice.Connection
	@private

	Runs a future without waiting for it, logging at warn if it fails or its thread errors. `onFailure` receives the
	error message when the future resolves Err.
]=]
function Connection.Prototype.runDetached(
	self: Connection,
	purpose: string,
	pending: future.FutureLike<string, ...any>,
	onFailure: ((failure: string) -> ())?
)
	local thread = coroutine.create(function()
		local result = (pending :: any):await()

		if result:isErr() then
			local failure = result:unwrapErr()

			self.logger:warn(`{purpose} failed: {failure}`)

			if onFailure then
				onFailure(failure)
			end
		end
	end)
	local resumed, resumeError = coroutine.resume(thread)

	if not resumed then
		self.logger:warn(`{purpose} thread errored:\n{debug.traceback(thread, tostring(resumeError))}`)
	end
end

--[=[
	@within Voice.Connection
	@private

	Sends the first voice heartbeat after Hello and starts the heartbeat loop. Does nothing if the connection has moved
	past `generation`.
]=]
function Connection.Prototype.startInitialHeartbeat(self: Connection, generation: number)
	return future.Future.new(function()
		local result = self.webSocket:heartbeatAsync(true):await()

		if self.generation ~= generation then
			self.logger:debug(`ignoring the first voice heartbeat of an older connect`)

			return
		end

		if result:isOk() then
			self.webSocket:heartbeatIn(self.webSocket.heartbeatInterval :: number)
		else
			self.logger:warn(`initial voice heartbeat failed: {result:unwrapErr()}`)
			self:recordDrop("heartbeatFailed", INTERNAL_ERROR_CLOSE_CODE)
		end
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Voice.Connection
	@private

	Runs UDP IP discovery after Ready and then Select Protocol. Does nothing past the point where the connection has
	moved beyond `generation`.
]=]
function Connection.Prototype.discoverAndSelectProtocol(self: Connection, generation: number)
	return future.Future.new(function()
		local discoveryResult = self.udp:discoverIpAsync():await()

		if self.generation ~= generation then
			self.logger:debug(`ignoring the UDP IP discovery of an older connect`)

			return
		end

		if discoveryResult:isErr() then
			self.logger:warn(`UDP IP discovery failed: {discoveryResult:unwrapErr()}`)
			self:recordDrop("handshakeFailed")

			return
		end

		local externalIp, externalPort = discoveryResult:unwrapOk()
		local offeredModes = self.udp.modes or {}
		local selectedMode = if table.find(offeredModes, ENCRYPTION_MODE_AES256_GCM)
				and sodium.aes256gcm.isAvailable()
			then ENCRYPTION_MODE_AES256_GCM
			else ENCRYPTION_MODE_XCHACHA20
		local selectResult = self:selectProtocolAsync(externalIp, externalPort, selectedMode):await()

		if self.generation ~= generation then
			self.logger:debug(`ignoring the Select Protocol result of an older connect`)

			return
		end

		if selectResult:isErr() then
			self.logger:warn(`select protocol failed: {selectResult:unwrapErr()}`)
			self:recordDrop("handshakeFailed")
		end
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Voice.Connection
	@private

	Sends op 4 through the gateway shard: a join of `channelId`, or the leave when it is nil. A join is dropped at the
	last moment if the connection has moved on or closed by then; the leave always goes out.
]=]
function Connection.Prototype.sendVoiceStateAsync(self: Connection, channelId: string?): future.FutureLike<string, nil>
	local generation = self.generation
	local payload = if channelId
		then stdPolyfills.serde.encode("json" :: any, {
			op = apiTypes.gateway.opcodes.VoiceStateUpdate,
			d = { guild_id = self.guildId, channel_id = channelId, self_mute = false, self_deaf = false },
		})
		else string.format(LEAVE_PAYLOAD_FORMAT, apiTypes.gateway.opcodes.VoiceStateUpdate, self.guildId)
	local isStillWanted = if channelId
		then function()
			return self.generation == generation and self.status ~= "closed"
		end
		else nil

	if channelId then
		self.voiceRequested = true
		self.logger:info(`requesting voice channel {channelId}`)
	else
		self.logger:info(`leaving voice in guild {self.guildId}`)
	end

	-- websocket 0.0.4's Shard type predates isStillWanted; later shards honour it and older ones ignore it.
	return (self.shard :: any):sendAsync(payload, false, isStillWanted)
end

--[=[
	@within Voice.Connection
	@private

	Sends the voice Identify payload to the voice gateway after the WebSocket connects.
]=]
function Connection.Prototype.identifyAsync(self: Connection)
	return future.Future.new(function()
		self.webSocket.sequenceAcknowledgement = -1

		self.logger:info(`sending voice identify`)

		local sent = self:sendAsync(stdPolyfills.serde.encode("json" :: any, {
			op = apiTypes.voice.opcodes.Identify,
			d = {
				server_id = self.guildId,
				user_id = self.userId,
				session_id = self.sessionId,
				token = self.token.value,
				max_dave_protocol_version = dave.sys.lib.daveMaxSupportedProtocolVersion(),
			},
		}, true)):await()

		assert(sent:isOk(), `identify send failed: {sent:unwrapErr()}`)
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Voice.Connection
	@private

	Sends the voice Resume payload to the voice gateway to resume an existing session.
]=]
function Connection.Prototype.resumeAsync(self: Connection)
	return future.Future.new(function()
		self.logger:info(`sending voice resume`)

		local sent = self:sendAsync(stdPolyfills.serde.encode("json" :: any, {
			op = apiTypes.voice.opcodes.Resume,
			d = {
				server_id = self.guildId,
				session_id = self.sessionId,
				token = self.token.value,
				seq_ack = self.webSocket.sequenceAcknowledgement,
			},
		}, true)):await()

		assert(sent:isOk(), `resume send failed: {sent:unwrapErr()}`)
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Voice.Connection
	@private

	Sends SelectProtocol after UDP IP discovery, committing to the negotiated encryption mode.
]=]
function Connection.Prototype.selectProtocolAsync(
	self: Connection,
	externalIp: string,
	externalPort: number,
	mode: string
)
	return future.Future.new(function()
		self.rtp.encryptionMode = mode

		self.logger:info(`selecting voice protocol: {externalIp}:{externalPort} mode={mode}`)

		local sent = self:sendAsync(stdPolyfills.serde.encode("json" :: any, {
			op = apiTypes.voice.opcodes.SelectProtocol,
			d = {
				protocol = "udp",
				data = {
					address = externalIp,
					port = externalPort,
					mode = mode,
				},
			},
		}, true)):await()

		assert(sent:isOk(), `select protocol send failed: {sent:unwrapErr()}`)
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Voice.Connection

	Sets the bot's speaking state. Pass a bitmask of speaking flags (Microphone = 1, Soundshare = 2, Priority = 4).
	Fails with `cannot set speaking: SSRC not assigned` before the voice server has assigned one, so op 5 never goes
	out without an ssrc, and fails when the send fails.
]=]
function Connection.Prototype.setSpeakingAsync(self: Connection, speakingFlags: number)
	return future.Future.new(function()
		local ssrc = self.udp.ssrc

		assert(ssrc, "cannot set speaking: SSRC not assigned")

		local sent = self:sendAsync(stdPolyfills.serde.encode("json" :: any, {
			op = apiTypes.voice.opcodes.Speaking,
			d = {
				speaking = speakingFlags,
				delay = 0,
				ssrc = ssrc,
			},
		}, true)):await()

		assert(sent:isOk(), `set speaking send failed: {sent:unwrapErr()}`)
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Voice.Connection

	Encrypts and sends a raw Opus audio frame over UDP. With DAVE, until `dave.mediaReady`, Opus silence goes out in
	its place, so no audio leaves without end-to-end encryption.
]=]
function Connection.Prototype.sendOpusAsync(self: Connection, audioFrame: buffer)
	return self.udp:sendOpusAsync(audioFrame, self.rtp, self.dave)
end

--[=[
	@within Voice.Connection
	@private

	Starts the UDP receive loop and keepalive for the current session; each ignores a second start.
]=]
function Connection.Prototype.startTransports(self: Connection)
	self.udp:startUdpReceiveLoop()
	self.udp:startKeepaliveLoop()
end

--[=[
	@within Voice.Connection
	@private

	Wakes the supervisor and any join waiters on the next scheduler step, so they never run inside the caller's stack.
]=]
function Connection.Prototype.wake(self: Connection)
	stdPolyfills.task.defer(function()
		self.onWake:invoke()
	end)
end

--[=[
	@within Voice.Connection
	@private

	Records a dropped socket or a failed handshake step for the supervisor, with `detail` saying what failed when the
	cause alone does not. Ignored before the first join and after the connection closes.
]=]
function Connection.Prototype.recordDrop(self: Connection, cause: DropCause, code: number?, detail: string?)
	if self.status == "closed" or self.status == "idle" then
		self.logger:debug(`ignoring a {cause} drop (code {tostring(code)}) while {self.status}`)

		return
	end

	self.logger:info(`voice connection dropped: {detail or cause} (code {tostring(code)})`)
	self.pendingDrop = { cause = cause, code = code, detail = detail }
	self:wake()
end

--[=[
	@within Voice.Connection
	@private

	Logs a drop that the supervisor discards because the step it is in replaces the socket anyway.
]=]
function Connection.Prototype.logDiscardedDrop(self: Connection, drop: DropFact?, context: string)
	if drop then
		self.logger:debug(`discarding a {drop.cause} drop (code {tostring(drop.code)}) {context}`)
	end
end

--[=[
	@within Voice.Connection
	@private

	Starts a timer that marks itself expired and wakes the supervisor after `seconds`.
]=]
function Connection.Prototype.startTimer(self: Connection, seconds: number): Timer
	local timer: Timer = { expired = false }

	timer.thread = stdPolyfills.task.delay(seconds, function()
		timer.expired = true
		self.onWake:invoke()
	end)

	return timer
end

--[=[
	@within Voice.Connection
	@private

	Whether any fact is waiting for the supervisor.
]=]
function Connection.Prototype.hasFacts(self: Connection): boolean
	if #self.pendingVoiceStates > 0 or self.pendingServer or self.pendingDrop then
		return true
	end

	return self.readySignalled
end

--[=[
	@within Voice.Connection
	@private

	Takes every recorded fact at once and clears them.
]=]
function Connection.Prototype.takeFacts(self: Connection): Facts
	local facts: Facts = {
		voiceStates = self.pendingVoiceStates,
		server = self.pendingServer,
		drop = self.pendingDrop,
		ready = self.readySignalled,
	}

	self.pendingVoiceStates = {}
	self.pendingServer = nil
	self.pendingDrop = nil
	self.readySignalled = false

	return facts
end

--[=[
	@within Voice.Connection
	@private

	Parks the supervisor until a fact is recorded, `timer` expires or the connection closes, then takes the facts. Nil
	when the connection closed.
]=]
function Connection.Prototype.waitForFacts(self: Connection, timer: Timer?): Facts?
	while self.status ~= "closed" and not self:hasFacts() and not (timer and timer.expired) do
		self.onWake:wait()
	end

	if self.status == "closed" then
		self.logger:debug(`voice supervisor stopping: the connection closed`)

		return
	end

	return self:takeFacts()
end

--[=[
	@within Voice.Connection
	@private

	Waits until the connection is ready (and, with `afterGeneration`, has reconnected since), closes, or
	`timeoutSeconds` pass. Returns whether it became ready and, if not, why.
]=]
function Connection.Prototype.awaitReady(
	self: Connection,
	timeoutSeconds: number?,
	afterGeneration: number?
): (boolean, string?)
	local timer = if timeoutSeconds then self:startTimer(timeoutSeconds) else nil

	local function isReady(): boolean
		return self.status == "ready" and (not afterGeneration or self.generation ~= afterGeneration)
	end

	while not isReady() and self.status ~= "closed" and not (timer and timer.expired) do
		self.onWake:wait()
	end

	stopTimer(timer)

	if isReady() then
		return true
	end

	if self.status == "closed" then
		return false, self.closeDetail
	end

	return false, `voice connection to {self.channelId} was not ready after {timeoutSeconds}s`
end

--[=[
	@within Voice.Connection
	@private

	Closes the connection for good:
	- sends the leave unless Discord already removed the bot, or `leaveSent` says the caller did
	- unsubscribes from the gateway
	- closes the socket and cleans the session
	- fires `onClosed` once
	- wakes the supervisor, which sees `closed` at its next check and returns

	A second close is a no-op.
]=]
function Connection.Prototype.close(
	self: Connection,
	reason: CloseReason,
	code: number?,
	detail: string,
	leaveSent: boolean?
)
	local dispatchDisconnect = self.dispatchDisconnect
	local shouldLeave = reason ~= "removed" and self.voiceRequested and not leaveSent
	local socketCloseCode = if reason == "left" and code then code else NORMAL_CLOSE_CODE

	if self.status == "closed" then
		self.logger:debug(`ignoring a second close ({reason}: {detail})`)

		return
	end

	self.generation += 1
	self.status = "closed"
	self.closeReason = reason
	self.closeDetail = detail
	self.dispatchDisconnect = nil
	self.webSocket.isResuming = false

	if reason == "left" then
		self.logger:info(`voice connection closed: {detail}`)
	else
		self.logger:warn(`voice connection closed ({reason}): {detail}`)
	end

	if shouldLeave then
		self:runDetached("voice leave", self:sendVoiceStateAsync(nil))
	end

	if dispatchDisconnect then
		dispatchDisconnect()
	end

	self.webSocket:forceClose(socketCloseCode)
	self:cleanupSession()
	self.onClosed:invoke(reason, code)
	self:wake()
end

--[=[
	@within Voice.Connection
	@private

	Starts the supervisor thread; its errors are logged at warn and close the connection with `gaveUp`.
]=]
function Connection.Prototype.startSupervisor(self: Connection, firstJoinSeconds: number)
	local thread = coroutine.create(function()
		local supervised, supervisorError =
			xpcall(self.supervise :: (...any) -> ...any, debug.traceback, self, firstJoinSeconds)

		if not supervised then
			self.logger:warn(`voice supervisor errored:\n{supervisorError}`)
			self:close("gaveUp", nil, "the voice supervisor errored")
		end
	end)
	local resumed, resumeError = coroutine.resume(thread)

	if not resumed then
		self.logger:warn(`voice supervisor failed to start:\n{debug.traceback(thread, tostring(resumeError))}`)
	end
end

--[=[
	@within Voice.Connection
	@private

	The supervisor: one join attempt bounded by the caller's timeout, then the monitor loop until the connection
	closes.
]=]
function Connection.Prototype.supervise(self: Connection, firstJoinSeconds: number)
	local deadline = self:startTimer(firstJoinSeconds)
	local outcome = self:attemptJoin(deadline)

	stopTimer(deadline)

	if outcome == "ready" then
		self:monitor()
	elseif outcome == "failed" then
		self:close(
			"joinTimedOut",
			nil,
			if deadline.expired
				then `voice connection to {self.channelId} was not ready after {firstJoinSeconds}s`
				else `voice connection to {self.channelId} failed: {self.lastFailure}`
		)
	else
		self.logger:debug(`voice supervisor stopping: the connection closed while joining`)
	end
end

--[=[
	@within Voice.Connection
	@private

	Waits until the gateway shard can carry op 4: its socket is up and its session is Ready or Resumed. Closes the
	connection with `shardDown` when the shard will never come back. Returns false when `timer` expires or the
	connection closes.
]=]
function Connection.Prototype.waitForShard(self: Connection, timer: Timer?): boolean
	local shard = self.shard
	local announced = false

	while self.status ~= "closed" do
		if shard.stayDisconnected then
			self:close("shardDown", nil, `gateway shard {shard.shardId} closed for good`)

			return false
		end

		if shard.socketActive and (shard.sessionOutcome == "Ready" or shard.sessionOutcome == "Resumed") then
			return true
		end

		if timer and timer.expired then
			self.lastFailure = `gateway shard {shard.shardId} was not ready in time`
			self.logger:warn(self.lastFailure)

			return false
		end

		if not announced then
			announced = true
			self.logger:info(`waiting for gateway shard {shard.shardId} before sending op 4`)
		end

		stdPolyfills.task.wait(SHARD_POLL_SECONDS)
	end

	self.logger:debug(`stopped waiting for the gateway shard: the voice connection closed`)

	return false
end

--[=[
	@within Voice.Connection
	@private

	One join attempt: waits for the shard, sends op 4, waits for both voice events, then connects. The first join
	passes its deadline timer, which also bounds the shard wait; a rejoin attempt gets its own deadline from its op 4
	and waits for the shard without one. A removal recorded before a rejoin's op 4 closes the connection; before the
	first join's op 4 it is a previous connection's leave and is ignored.
]=]
function Connection.Prototype.attemptJoin(self: Connection, firstJoinTimer: Timer?): AttemptOutcome
	self.status = "signalling"

	if not self:waitForShard(firstJoinTimer) then
		return if self.status == "closed" then "closed" else "failed"
	end

	local discarded = self:takeFacts()

	for _, voiceState in discarded.voiceStates do
		if not voiceState.channelId and not firstJoinTimer then
			self:close("removed", nil, "removed from the voice channel before the rejoin")

			return "closed"
		end
	end

	if #discarded.voiceStates > 0 or discarded.server then
		self.logger:debug(`discarding voice events from before this op 4; Discord answers it with a fresh pair`)
	end

	self:logDiscardedDrop(discarded.drop, "from before this op 4")
	self.sessionId = ""

	local sent = self:sendVoiceStateAsync(self.channelId):await()

	if self.status == "closed" then
		self.logger:debug(`voice supervisor stopping: the connection closed while op 4 was sending`)

		return "closed"
	end

	if sent:isErr() then
		self.lastFailure = `op 4 for voice channel {self.channelId} failed to send: {sent:unwrapErr()}`
		self.logger:warn(self.lastFailure)

		return "failed"
	end

	local timer = firstJoinTimer or self:startTimer(JOIN_TIMEOUT_SECONDS)
	local signalled = self:signal(timer)
	local outcome: AttemptOutcome = if signalled == "signalled"
		then self:connect(timer, false)
		elseif signalled == "failed" then "failed"
		else "closed"

	if timer ~= firstJoinTimer then
		stopTimer(timer)
	end

	return outcome
end

--[=[
	@within Voice.Connection
	@private

	Waits for this channel's VOICE_STATE_UPDATE and a VOICE_SERVER_UPDATE with an endpoint. A null-channel update before
	the matching one is a previous connection's leave echo and is ignored; after it, it is a removal.
]=]
function Connection.Prototype.signal(self: Connection, timer: Timer): SignalOutcome
	local matched = false
	local server: ServerFact? = nil
	local sawServer = false

	while true do
		local facts = self:waitForFacts(timer)

		if not facts then
			return "closed"
		end

		self:logDiscardedDrop(facts.drop, "while signalling; no voice socket is open yet")

		for _, voiceState in facts.voiceStates do
			if voiceState.channelId == self.channelId then
				matched = true
				self.sessionId = voiceState.sessionId
			elseif matched and not voiceState.channelId then
				self:close("removed", nil, "removed from the voice channel while joining")

				return "closed"
			else
				self.logger:debug(
					`ignoring VOICE_STATE_UPDATE for {voiceState.channelId or "no channel"} while joining {self.channelId}`
				)
			end
		end

		if facts.server and facts.server.endpoint then
			server = facts.server
			sawServer = true
		elseif facts.server then
			self.logger:debug(`VOICE_SERVER_UPDATE without an endpoint while joining; waiting for the next one`)
		end

		if matched and server then
			self.token = secret.new(server.token)
			self.endpoint = server.endpoint :: string

			return "signalled"
		end

		if timer.expired then
			self.lastFailure = if sawServer
				then `VOICE_SERVER_UPDATE arrived but no VOICE_STATE_UPDATE; the gateway needs the GuildVoiceStates intent`
				else `Discord did not answer op 4 for voice channel {self.channelId}`
			self.logger:warn(self.lastFailure)

			return "failed"
		end
	end
end

--[=[
	@within Voice.Connection
	@private

	Opens a voice socket (fresh or resuming) and waits for Session Description or Resumed, as `awaitSession`
	describes. A failed connect retires its generation, so a socket still in its handshake is closed when it opens.
]=]
function Connection.Prototype.connect(self: Connection, timer: Timer, resuming: boolean): AttemptOutcome
	local generation = self.generation + 1

	self.generation = generation
	self.status = if resuming then "resuming" else "connecting"
	self.lastConnectResumed = resuming
	self.webSocket.isResuming = resuming
	self.pendingDrop = nil
	self.readySignalled = false
	self.webSocket:forceClose(NORMAL_CLOSE_CODE)

	if not resuming then
		self:cleanupSession()
	end

	self:startOpening(generation)

	local outcome: AttemptOutcome = self:awaitSession(timer)

	if outcome == "failed" then
		self.generation += 1
	end

	return outcome
end

--[=[
	@within Voice.Connection
	@private

	Opens the voice socket for `generation` on its own thread, so the supervisor stops waiting at its deadline even
	when the handshake never finishes. A failed open is recorded as a drop while that connect is still current.
]=]
function Connection.Prototype.startOpening(self: Connection, generation: number)
	local thread = coroutine.create(function()
		local opened, openError = pcall(self.openVoiceSocket :: (...any) -> ...any, self, generation)

		if not opened and self.generation == generation then
			self:recordDrop("openFailed", nil, `the voice socket to {self.endpoint} did not open: {openError}`)
		elseif not opened then
			self.logger:debug(`a voice socket for an older connect did not open: {openError}`)
		end
	end)
	local resumed, resumeError = coroutine.resume(thread)

	if not resumed then
		self.logger:warn(`voice socket open thread errored:\n{debug.traceback(thread, tostring(resumeError))}`)
	end
end

--[=[
	@within Voice.Connection
	@private

	Waits for Session Description or Resumed on the socket `connect` is opening. A removal closes the connection, a
	fatal close code closes it with `rejected`, and any other drop, a move or the deadline fails the attempt.
]=]
function Connection.Prototype.awaitSession(self: Connection, timer: Timer): AttemptOutcome
	while true do
		local facts = self:waitForFacts(timer)

		if not facts then
			return "closed"
		end

		for _, voiceState in facts.voiceStates do
			if not voiceState.channelId then
				self:close("removed", nil, "removed from the voice channel")

				return "closed"
			end

			if voiceState.channelId ~= self.channelId then
				self.lastFailure = `moved to voice channel {voiceState.channelId} while connecting`
				self.logger:info(self.lastFailure)
				self.channelId = voiceState.channelId
				self.sessionId = voiceState.sessionId

				return "failed"
			end

			self.sessionId = voiceState.sessionId
		end

		if facts.server then
			self.logger:debug(
				`ignoring a VOICE_SERVER_UPDATE while {self.status}; a failed attempt asks for a fresh one`
			)
		end

		if facts.drop then
			local code = facts.drop.code
			local meaning = if code then FATAL_CLOSE_MEANINGS[code] else nil

			if meaning then
				self:close("rejected", code, `voice gateway closed with {code}: {meaning}`)

				return "closed"
			end

			self.lastFailure =
				`voice {self.status} failed: {facts.drop.detail or facts.drop.cause} (code {tostring(code)})`
			self.logger:warn(self.lastFailure)

			return "failed"
		end

		if facts.ready then
			return "ready"
		end

		if timer.expired then
			self.lastFailure = if self.webSocket.socketOpening
				then `the voice socket to {self.endpoint} did not open within the deadline`
				else `voice connection to {self.channelId} was not ready within its deadline`
			self.logger:warn(self.lastFailure)

			return "failed"
		end
	end
end

--[=[
	@within Voice.Connection
	@private

	The steady state: marks the connection ready (firing `onReady` for a new session or `onResumed` after a resume,
	once per connect), waits for a change, recovers from it, and repeats until the connection closes. Every
	transition into `ready` follows a connect, so each fires one of the two events.
]=]
function Connection.Prototype.monitor(self: Connection)
	while self.status ~= "closed" do
		local isNewConnect = self.announcedGeneration ~= self.generation

		self.status = "ready"
		self.readyShardSessionId = self.shard.sessionId
		self.announcedGeneration = self.generation
		self:wake()

		if isNewConnect and self.lastConnectResumed then
			self.onResumed:invoke()
		elseif isNewConnect then
			self.onReady:invoke()
		end

		local facts = self:awaitChange()

		if not facts or not self:recover(facts) then
			self.logger:debug(`voice supervisor stopping: the connection closed`)

			return
		end
	end
end

--[=[
	@within Voice.Connection
	@private

	Waits while ready for a voice state, server or drop fact. After `STABLE_SECONDS` without one, the recovery attempt
	counter resets.
]=]
function Connection.Prototype.awaitChange(self: Connection): Facts?
	local stableTimer = if self.recoveryAttempts > 0 then self:startTimer(STABLE_SECONDS) else nil

	while true do
		local facts = self:waitForFacts(stableTimer)

		if not facts then
			stopTimer(stableTimer)

			return
		end

		if stableTimer and stableTimer.expired then
			self.logger:debug(`voice connection stayed ready for {STABLE_SECONDS}s; resetting the recovery attempts`)
			self.recoveryAttempts = 0
			stableTimer = nil
		end

		if #facts.voiceStates > 0 or facts.server or facts.drop then
			stopTimer(stableTimer)

			return facts
		end
	end
end

--[=[
	@within Voice.Connection
	@private

	Whether the facts change where the connection should be: a removal, a move or a server update.
]=]
function Connection.Prototype.isChange(self: Connection, facts: Facts): boolean
	for _, voiceState in facts.voiceStates do
		if voiceState.channelId ~= self.channelId then
			return true
		end
	end

	if facts.server then
		return true
	end

	return false
end

--[=[
	@within Voice.Connection
	@private

	Acts on the facts, in this order: a removal closes, a move follows the new channel, a server update follows the
	server, and a drop recovers by its close code. Without a removal, move, server update or drop, it returns true
	while the voice socket stands, and rejoins when it does not. Returns whether the connection is ready again.
]=]
function Connection.Prototype.recover(self: Connection, facts: Facts): boolean
	local latestState = facts.voiceStates[#facts.voiceStates]

	for _, voiceState in facts.voiceStates do
		if not voiceState.channelId then
			self:close("removed", nil, "removed from the voice channel")

			return false
		end
	end

	if latestState and latestState.channelId ~= self.channelId then
		self:logDiscardedDrop(facts.drop, "because the move replaces the voice socket")

		return self:followMove(latestState, facts.server)
	end

	if latestState then
		self.sessionId = latestState.sessionId
	end

	if facts.server then
		self:logDiscardedDrop(facts.drop, "because the voice server change replaces the voice socket")

		return self:followServer(facts.server)
	end

	if facts.drop then
		return self:recoverFromDrop(facts.drop)
	end

	if self.status ~= "ready" then
		self.logger:info(
			`back in voice channel {self.channelId} with no voice server update and no voice socket; rejoining`
		)

		return self:rejoin(nil)
	end

	self.logger:debug(`voice state update for the current channel; nothing to recover`)

	return true
end

--[=[
	@within Voice.Connection
	@private

	Follows a move to another channel. Its VOICE_SERVER_UPDATE can arrive with the move, before it (a server update
	remembered within the grace) or after it: the first two are connected to at once, and the last is waited for by
	`awaitServerForMove`. A remembered server completes one move only.
]=]
function Connection.Prototype.followMove(self: Connection, voiceState: VoiceStateFact, server: ServerFact?): boolean
	local recentTimer = self.recentServerTimer
	local recentServer = if recentTimer and not recentTimer.expired then self.recentServer else nil
	local serverUpdate = server or recentServer

	self.logger:info(`moved from voice channel {self.channelId} to {voiceState.channelId}`)
	self.channelId = voiceState.channelId :: string
	self.sessionId = voiceState.sessionId
	self.status = "disconnected"
	self:forgetRecentServer()

	if serverUpdate and serverUpdate.endpoint then
		return self:connectTo(serverUpdate, nil)
	end

	return self:awaitServerForMove()
end

--[=[
	@within Voice.Connection
	@private

	Waits up to `DISCONNECT_GRACE_SECONDS` for the VOICE_SERVER_UPDATE of a move and connects to it, or rejoins with
	op 4 for the new channel when none arrives, because the old token is dead after a channel change. A removal
	closes the connection and a further move updates the channel.
]=]
function Connection.Prototype.awaitServerForMove(self: Connection): boolean
	local grace = self:startTimer(DISCONNECT_GRACE_SECONDS)

	self.status = "disconnected"

	while not grace.expired do
		local facts = self:waitForFacts(grace)

		if not facts then
			stopTimer(grace)

			return false
		end

		self:logDiscardedDrop(facts.drop, "while waiting for the voice server of a move")

		for _, laterState in facts.voiceStates do
			if not laterState.channelId then
				stopTimer(grace)
				self:close("removed", nil, "removed from the voice channel")

				return false
			end

			self.channelId = laterState.channelId
			self.sessionId = laterState.sessionId
		end

		if facts.server and facts.server.endpoint then
			stopTimer(grace)

			return self:connectTo(facts.server, nil)
		end
	end

	self.logger:warn(`no voice server within {DISCONNECT_GRACE_SECONDS}s of the move to {self.channelId}; rejoining`)

	return self:rejoin(nil)
end

--[=[
	@within Voice.Connection
	@private

	Follows a VOICE_SERVER_UPDATE: connects to the new endpoint, or waits for a replacement when it has none.
]=]
function Connection.Prototype.followServer(self: Connection, server: ServerFact): boolean
	if server.endpoint then
		self.logger:info(`voice server changed to {server.endpoint}; reconnecting`)

		return self:connectTo(server, self:rememberServer(server))
	end

	return self:awaitReplacementServer()
end

--[=[
	@within Voice.Connection
	@private

	Remembers a VOICE_SERVER_UPDATE that arrived without a move for `DISCONNECT_GRACE_SECONDS`, because the move it
	belongs to may follow it, and returns that window's timer.
]=]
function Connection.Prototype.rememberServer(self: Connection, server: ServerFact): Timer
	local grace = self:startTimer(DISCONNECT_GRACE_SECONDS)

	stopTimer(self.recentServerTimer)
	self.recentServer = server
	self.recentServerTimer = grace

	return grace
end

--[=[
	@within Voice.Connection
	@private

	Forgets the remembered VOICE_SERVER_UPDATE once a move has used it or brought its own.
]=]
function Connection.Prototype.forgetRecentServer(self: Connection)
	stopTimer(self.recentServerTimer)
	self.recentServer = nil
	self.recentServerTimer = nil
end

--[=[
	@within Voice.Connection
	@private

	Connects fresh to `server` without op 4 and rejoins when the connect fails. A move that lands during the connect
	is completed by `server` only while `moveGrace` (the window from when that server update arrived) is still open,
	which connects again once; after the window the move waits for its own server update.
]=]
function Connection.Prototype.connectTo(self: Connection, server: ServerFact, moveGrace: Timer?): boolean
	local channelId = self.channelId
	local timer = self:startTimer(JOIN_TIMEOUT_SECONDS)

	self.token = secret.new(server.token)
	self.endpoint = server.endpoint :: string

	local outcome = self:connect(timer, false)
	local moved = self.channelId ~= channelId
	local withinGrace = if moveGrace then not moveGrace.expired else false

	stopTimer(timer)

	if outcome == "failed" and moved and withinGrace then
		self.logger:info(
			`the move to voice channel {self.channelId} landed within {DISCONNECT_GRACE_SECONDS}s of the server update; connecting again with it`
		)
		self:forgetRecentServer()

		return self:connectTo(server, nil)
	end

	if outcome == "failed" and moved then
		self.logger:info(
			`the move to voice channel {self.channelId} landed while connecting to a server that is not its own; waiting for its server update`
		)
		self:forgetRecentServer()

		return self:awaitServerForMove()
	end

	if outcome == "failed" then
		return self:rejoin(nil)
	end

	return outcome == "ready"
end

--[=[
	@within Voice.Connection
	@private

	The voice server is going away: closes the socket, keeps the connection, and waits up to `JOIN_TIMEOUT_SECONDS`
	for the replacement server before rejoining.
]=]
function Connection.Prototype.awaitReplacementServer(self: Connection): boolean
	local timer = self:startTimer(JOIN_TIMEOUT_SECONDS)

	self.logger:info(`voice server is going away; waiting up to {JOIN_TIMEOUT_SECONDS}s for its replacement`)
	self.status = "disconnected"
	self.webSocket:forceClose(NORMAL_CLOSE_CODE)

	while not timer.expired do
		local facts = self:waitForFacts(timer)

		if not facts then
			stopTimer(timer)

			return false
		end

		self:logDiscardedDrop(facts.drop, "while waiting for the replacement voice server")

		for _, voiceState in facts.voiceStates do
			if not voiceState.channelId then
				stopTimer(timer)
				self:close("removed", nil, "removed from the voice channel")

				return false
			end

			self.channelId = voiceState.channelId
			self.sessionId = voiceState.sessionId
		end

		if facts.server and facts.server.endpoint then
			stopTimer(timer)

			return self:connectTo(facts.server, self:rememberServer(facts.server))
		end
	end

	self.logger:warn(`no replacement voice server within {JOIN_TIMEOUT_SECONDS}s; rejoining`)

	return self:rejoin(nil)
end

--[=[
	@within Voice.Connection
	@private

	Recovers from a drop by its close code: fatal codes close with `rejected`, resumable ones resume once, 4014 and
	4022 wait out the grace, and everything else rejoins.
]=]
function Connection.Prototype.recoverFromDrop(self: Connection, drop: DropFact): boolean
	local code = drop.code
	local meaning = if code then FATAL_CLOSE_MEANINGS[code] else nil
	local resumable = drop.cause == "zombie" or (drop.cause == "closed" and code and RESUMABLE_CLOSE_CODES[code])
	local graceful = drop.cause == "closed" and code and GRACE_CLOSE_CODES[code]

	if meaning then
		self:close("rejected", code, `voice gateway closed with {code}: {meaning}`)

		return false
	end

	if resumable then
		return self:resume(code)
	end

	if graceful then
		return self:graceAfterDisconnect(code :: number)
	end

	return self:rejoin(code)
end

--[=[
	@within Voice.Connection
	@private

	After 4014 or 4022:
	- waits `DISCONNECT_GRACE_SECONDS`, then for the gateway shard;
	- then acts on any removal, move or server update;
	- without one, rejoins only when the gateway session was replaced since the connection was ready, and otherwise
	  closes with `rejected` as Discord's "should not reconnect" says.
]=]
function Connection.Prototype.graceAfterDisconnect(self: Connection, code: number): boolean
	local grace = self:startTimer(DISCONNECT_GRACE_SECONDS)
	local gathered: Facts = { voiceStates = {}, ready = false }

	self.logger:info(`voice gateway closed with {code}; waiting {DISCONNECT_GRACE_SECONDS}s to see why`)
	self.status = "disconnected"

	while not grace.expired do
		local facts = self:waitForFacts(grace)

		if not facts then
			stopTimer(grace)

			return false
		end

		self:logDiscardedDrop(facts.drop, "during the disconnect grace; the socket is already closed")
		table.move(facts.voiceStates, 1, #facts.voiceStates, #gathered.voiceStates + 1, gathered.voiceStates)
		gathered.server = facts.server or gathered.server
	end

	if not self:waitForShard(nil) then
		return false
	end

	local replayed = self:takeFacts()

	self:logDiscardedDrop(replayed.drop, "after the disconnect grace; the socket is already closed")
	table.move(replayed.voiceStates, 1, #replayed.voiceStates, #gathered.voiceStates + 1, gathered.voiceStates)
	gathered.server = replayed.server or gathered.server

	if self:isChange(gathered) then
		return self:recover(gathered)
	end

	if self.shard.sessionId ~= self.readyShardSessionId then
		self.logger:info(`the gateway session changed since the voice connection was ready; rejoining`)

		return self:rejoin(code)
	end

	self:close("rejected", code, `voice gateway closed with {code} and Discord sent nothing else`)

	return false
end

--[=[
	@within Voice.Connection
	@private

	Resumes the session once, counted as an attempt; any failure falls back to a rejoin.
]=]
function Connection.Prototype.resume(self: Connection, code: number?): boolean
	if not self:spendAttempt(code) then
		return false
	end

	local timer = self:startTimer(JOIN_TIMEOUT_SECONDS)

	self.logger:info(`resuming the voice session (attempt {self.recoveryAttempts}/{MAX_RECONNECT_ATTEMPTS})`)

	local outcome = self:connect(timer, true)

	stopTimer(timer)
	self.webSocket.isResuming = false

	if outcome == "failed" then
		return self:rejoin(code)
	end

	return outcome == "ready"
end

--[=[
	@within Voice.Connection
	@private

	Counts a recovery attempt, or closes the connection with `gaveUp` when all of them are spent.
]=]
function Connection.Prototype.spendAttempt(self: Connection, code: number?): boolean
	if self.recoveryAttempts >= MAX_RECONNECT_ATTEMPTS then
		self:close("gaveUp", code, `voice rejoin gave up after {MAX_RECONNECT_ATTEMPTS} attempts`)

		return false
	end

	self.recoveryAttempts += 1

	return true
end

--[=[
	@within Voice.Connection
	@private

	Rejoins with backoff (1, 2, 4, 8 then 16 seconds by attempt number) until an attempt reaches ready or the attempts
	run out.
]=]
function Connection.Prototype.rejoin(self: Connection, code: number?): boolean
	while self:spendAttempt(code) do
		local attempt = self.recoveryAttempts
		local delaySeconds = math.min(2 ^ (attempt - 1), MAX_RECONNECT_DELAY_SECONDS)

		self.status = "disconnected"
		self.webSocket:forceClose(NORMAL_CLOSE_CODE)
		self.logger:warn(
			`rejoining voice channel {self.channelId} in {delaySeconds}s (attempt {attempt}/{MAX_RECONNECT_ATTEMPTS})`
		)

		if not self:backOff(delaySeconds) then
			return false
		end

		local outcome = self:attemptJoin(nil)

		if outcome ~= "failed" then
			return outcome == "ready"
		end

		self.logger:warn(`voice rejoin attempt {attempt}/{MAX_RECONNECT_ATTEMPTS} failed: {self.lastFailure}`)
	end

	return false
end

--[=[
	@within Voice.Connection
	@private

	Waits out a rejoin backoff. A removal closes the connection, a move updates the channel for the next attempt, and
	a server update is discarded because the next op 4 asks for a fresh one.
]=]
function Connection.Prototype.backOff(self: Connection, seconds: number): boolean
	local timer = self:startTimer(seconds)

	while not timer.expired do
		local facts = self:waitForFacts(timer)

		if not facts then
			stopTimer(timer)

			return false
		end

		self:logDiscardedDrop(facts.drop, "during a rejoin backoff; the next attempt opens a new socket")

		for _, voiceState in facts.voiceStates do
			if not voiceState.channelId then
				stopTimer(timer)
				self:close("removed", nil, "removed from the voice channel")

				return false
			end

			if voiceState.channelId ~= self.channelId then
				self.logger:info(`moved to voice channel {voiceState.channelId} during a rejoin backoff`)
				self.channelId = voiceState.channelId
			end
		end

		if facts.server then
			self.logger:debug(
				`discarding a VOICE_SERVER_UPDATE during a rejoin backoff; the next op 4 asks for a fresh one`
			)
		end
	end

	return true
end

--[=[
	@within Voice.Connection

	Builds a connection for one guild's voice channel; `joinAsync` joins it. The settings:
	- `shard`: the gateway shard that carries `guildId`, which sends op 4 and receives the voice events;
	- `guildId` and `channelId`: the channel to join;
	- `userId`: the bot's user id, which picks the bot's own VOICE_STATE_UPDATE out of the guild's;
	- `logLevel`: the level of the connection's logger, `VoiceConnection<guildId>`, which its transports share.

	Classes' `channel:joinAsync()` builds and joins one, and resolves with it.
]=]
function Connection.Interface.new(settings: {
	shard: websocket.Shard,
	guildId: string,
	channelId: string,
	userId: string,
	logLevel: logger.LogLevel,
}): Connection
	local connectionLogger = logger.new(`VoiceConnection<{settings.guildId}>`, settings.logLevel)
	local self: Connection = setmetatable(
		{
			webSocket = voiceWebsocket.new(connectionLogger),
			udp = voiceUdp.new(connectionLogger),
			rtp = voiceRtpCrypto.new(),
			dave = voiceDaveManager.new(connectionLogger),

			jitters = {} :: { [number]: voiceJitter.Jitter },

			shard = settings.shard,
			guildId = settings.guildId,
			channelId = settings.channelId,
			userId = settings.userId,
			sessionId = "",
			token = secret.new(""),
			endpoint = "",
			status = "idle",
			generation = 0,
			announcedGeneration = 0,
			lastConnectResumed = false,
			closeDetail = "",
			recoveryAttempts = 0,
			voiceRequested = false,
			pendingVoiceStates = {},
			readySignalled = false,
			lastFailure = "",
			decodeAudio = true,

			onConnected = emitter.new(),
			onDisconnected = emitter.new(),
			onReady = emitter.new(),
			onHeartbeat = emitter.new(),
			onRawMessage = emitter.new(),
			onSpeaking = emitter.new(),
			onClientConnect = emitter.new(),
			onClientDisconnect = emitter.new(),
			onDaveEpochTransition = emitter.new(),
			onMediaReady = emitter.new(),
			onRawAudioFrame = emitter.new(),
			onAudioFrame = emitter.new(),
			onClosed = emitter.new(),
			onResumed = emitter.new(),
			onWake = emitter.new(),

			logger = connectionLogger,
		} :: any,
		{ __index = Connection.Prototype }
	)

	self.webSocket.onConnected = function()
		self.onConnected:invoke()
	end

	self.webSocket.onDisconnected = function(code, closedBySelf)
		self.onDisconnected:invoke(code, closedBySelf)
	end

	self.webSocket.onMessage = function(payload)
		self.onRawMessage:invoke(payload)
	end

	self.webSocket.onZombified = function()
		self:recordDrop("zombie")
	end

	self.dave.sendMessage = function(message: string | buffer, purpose: string)
		self:runDetached(purpose, self.webSocket:sendAsync(message))
	end

	self.dave.onTransitionExecuted = function(rosterSize: number)
		self.onDaveEpochTransition:invoke(rosterSize)
	end

	self.dave.onMediaReadyChanged = function(ready: boolean)
		self:wake()

		if ready then
			self.onMediaReady:invoke()
		end
	end

	self.udp.decryptPacket = function(rawPacket: buffer): (buffer?, string?)
		if not self.rtp.secretKey then
			return nil, "it arrived before the secret key"
		end

		return self.rtp:decryptRtp(
			rawPacket,
			self.dave.ssrcToUserId,
			self.dave.daveDecryptors,
			self.dave.mediaProtocolVersion,
			self.dave:hasPendingDowngrade()
		)
	end

	self.udp.onAudioPacket = function(ssrc: number, sequence: number, audioFrame: buffer)
		local jitter = self.jitters[ssrc]

		if not jitter then
			local newJitter = voiceJitter.new(sequence, self.logger)

			jitter = newJitter
			self.jitters[ssrc] = jitter

			newJitter:start(function(_: number, packet: buffer)
				self.onRawAudioFrame:invoke({ userId = self.dave.ssrcToUserId[ssrc], ssrc = ssrc, frame = packet })
			end, function(pcm: buffer)
				self.onAudioFrame:invoke({ userId = self.dave.ssrcToUserId[ssrc], ssrc = ssrc, frame = pcm })
			end, function(): boolean
				return self.decodeAudio
			end)
		end

		jitter:push(sequence, audioFrame)
	end

	self.onRawMessage:listen(function(payload: any)
		local opcode: number = payload.op
		local payloadData: any = payload.d

		if payload.seq then
			self.webSocket.sequenceAcknowledgement = payload.seq
		end

		if opcode == apiTypes.voice.opcodes.Hello then
			self.logger:info(`received voice Hello, starting heartbeat`)

			self.webSocket.heartbeatInterval = payloadData.heartbeat_interval

			local helloGeneration = self.generation

			self:runDetached("initial voice heartbeat", self:startInitialHeartbeat(helloGeneration), function()
				if self.generation == helloGeneration then
					self:recordDrop("heartbeatFailed", INTERNAL_ERROR_CLOSE_CODE)
				end
			end)
		elseif opcode == apiTypes.voice.opcodes.HeartbeatACK then
			self.webSocket.heartbeatAcknowledged = true
			self.webSocket.heartbeatPing = os.clock() - (self.webSocket.heartbeatClockTime :: number)

			self.logger:info(`voice heartbeat ack, ping: '{string.sub(tostring(self.webSocket.heartbeatPing), 1, 7)}'`)

			self.onHeartbeat:invoke(self.webSocket.heartbeatPing)
		elseif opcode == apiTypes.voice.opcodes.Ready then
			self.logger:info(
				`received voice Ready, ssrc={payloadData.ssrc} udp={payloadData.ip}:{payloadData.port} modes={#payloadData.modes}`
			)

			self.udp.ssrc = payloadData.ssrc
			self.udp.udpIp = payloadData.ip
			self.udp.udpPort = payloadData.port
			self.udp.modes = payloadData.modes
			self.udp.streams = payloadData.streams
			self.udp.experiments = payloadData.experiments

			local readyGeneration = self.generation

			self:runDetached(
				"UDP discovery and Select Protocol",
				self:discoverAndSelectProtocol(readyGeneration),
				function()
					if self.generation == readyGeneration then
						self:recordDrop("handshakeFailed")
					end
				end
			)
		elseif opcode == apiTypes.voice.opcodes.SessionDescription then
			local confirmedMode = payloadData.mode
			local secretKeyArray = payloadData.secret_key or {}
			local daveProtocolVersion = payloadData.dave_protocol_version
			local secretKey = buffer.create(SECRET_KEY_SIZE)

			self.logger:info(`received voice SessionDescription, mode={confirmedMode}`)

			if #secretKeyArray ~= SECRET_KEY_SIZE then
				self.logger:warn(
					`SessionDescription carried a {#secretKeyArray}-byte secret key; expected {SECRET_KEY_SIZE}`
				)
				self:recordDrop("badKey")

				return
			end

			if self.rtp.encryptionMode and confirmedMode ~= self.rtp.encryptionMode then
				self.logger:warn(
					`SessionDescription mode '{confirmedMode}' differs from negotiated '{self.rtp.encryptionMode}', updating`
				)
			end

			for index, byte in secretKeyArray do
				buffer.writeu8(secretKey, index - 1, byte)
			end

			self.rtp.encryptionMode = confirmedMode
			self.rtp.secretKey = secretKey

			self.dave:handleSessionDescription(daveProtocolVersion or 0, self.channelId, self.userId, self.udp.ssrc)
			self:startTransports()
			self.readySignalled = true
			self:wake()
		elseif opcode == apiTypes.voice.opcodes.Resumed then
			self.logger:notice(`voice session resumed successfully`)
			self:startTransports()
			self.readySignalled = true
			self:wake()
		elseif opcode == apiTypes.voice.opcodes.ClientsConnect then
			local userIds: { string } = payloadData.user_ids

			self.logger:info(`received voice channel members: {#userIds} user(s)`)
			self.dave:handleClientsConnect(userIds)

			for _, userId in userIds do
				self.onClientConnect:invoke({ userId = userId })
			end
		elseif opcode == apiTypes.voice.opcodes.Speaking then
			self.dave.ssrcToUserId[payloadData.ssrc] = payloadData.user_id

			self.onSpeaking:invoke({
				userId = payloadData.user_id,
				ssrc = payloadData.ssrc,
				speaking = payloadData.speaking,
			})
		elseif opcode == apiTypes.voice.opcodes.Video then
			self.logger:debug(`received voice Video: user={payloadData.user_id} ssrc={payloadData.video_ssrc}`)
		elseif opcode == apiTypes.voice.opcodes.ClientDisconnect then
			self.logger:info(`received ClientDisconnect: user={payloadData.user_id}`)
			self.dave:handleClientDisconnect(payloadData.user_id)

			for ssrc, userId in self.dave.ssrcToUserId do
				if userId == payloadData.user_id then
					self.dave.ssrcToUserId[ssrc] = nil

					local jitter = self.jitters[ssrc]

					if jitter then
						jitter:destroy()
						self.jitters[ssrc] = nil
					end

					break
				end
			end

			self.onClientDisconnect:invoke({ userId = payloadData.user_id })
		elseif opcode == apiTypes.voice.opcodes.SessionUpdate then
			self.logger:debug(
				`received voice SessionUpdate: audio_codec={payloadData.audio_codec} video_codec={payloadData.video_codec}`
			)
		elseif opcode == apiTypes.voice.opcodes.MediaSinkWants then
			self.logger:debug(`received MediaSinkWants from server - bot cannot adjust stream quality`)
		elseif opcode == apiTypes.voice.opcodes.VoiceBackendVersion then
			self.logger:info(`voice backend version: voice={payloadData.voice} rtc_worker={payloadData.rtc_worker}`)
		elseif opcode == apiTypes.voice.opcodes.ChannelOptionsUpdate then
			self.logger:debug(`received voice ChannelOptionsUpdate: bitrate={payloadData.bitrate}`)
		elseif opcode == apiTypes.voice.opcodes.ClientFlags then
			self.logger:debug(`received ClientFlags - opcode is erroneously sent in stream contexts`)
		elseif opcode == apiTypes.voice.opcodes.ClientPlatform then
			self.logger:debug(`received ClientPlatform - opcode is erroneously sent in stream contexts`)
		elseif opcode == apiTypes.voice.opcodes.DaveProtocolPrepareTransition then
			self.dave:handlePrepareTransition(payloadData)
		elseif opcode == apiTypes.voice.opcodes.DaveProtocolExecuteTransition then
			self.dave:handleExecuteTransition(payloadData)
		elseif opcode == apiTypes.voice.opcodes.DaveProtocolTransitionReady then
			self.logger:info(`DAVE protocol transition ready (server ack)`)
		elseif opcode == apiTypes.voice.opcodes.DaveProtocolPrepareEpoch then
			self.dave:handlePrepareEpoch(payloadData)
		elseif opcode == apiTypes.voice.opcodes.DaveMlsExternalSenderPackage then
			self.dave:handleExternalSender(payloadData)
		elseif opcode == apiTypes.voice.opcodes.DaveMlsProposals then
			self.dave:handleProposals(payloadData)
		elseif opcode == apiTypes.voice.opcodes.DaveMlsAnnounceCommitTransition then
			self.dave:handleCommitTransition(payloadData)
		elseif opcode == apiTypes.voice.opcodes.DaveMlsWelcome then
			self.dave:handleWelcome(payloadData)
		end
	end)

	self.onConnected:listen(function()
		local isResuming = self.webSocket.isResuming
		local result

		if isResuming then
			self.logger:info(`sending voice resume (op 7)`)
			result = self:resumeAsync():await()
		else
			result = self:identifyAsync():await()
		end

		if result:isErr() then
			self.logger:warn(`voice {if isResuming then "resume" else "identify"} failed: {result:unwrapErr()}`)
		end
	end)

	self.onDisconnected:listen(function(code: number?, closedBySelf: boolean?)
		if closedBySelf then
			self.logger:debug(`voice socket closed by this client (code {tostring(code)})`)

			return
		end

		self.webSocket:stopHeartbeat()
		self:recordDrop("closed", code or NO_CLOSE_CODE)
	end)

	self.dispatchDisconnect = settings.shard.onSocketDispatch:listen(function(payload: any)
		local data = payload.d

		if
			payload.t == apiTypes.gateway.receiveEvents.VoiceStateUpdate
			and data.user_id == self.userId
			and data.guild_id == self.guildId
		then
			self.logger:info(`received VOICE_STATE_UPDATE: channel {data.channel_id or "none"}`)
			table.insert(self.pendingVoiceStates, { channelId = data.channel_id, sessionId = data.session_id })
			self:wake()
		elseif payload.t == apiTypes.gateway.receiveEvents.VoiceServerUpdate and data.guild_id == self.guildId then
			self.logger:info(`received VOICE_SERVER_UPDATE: endpoint {data.endpoint or "none"}`)
			self.pendingServer = { token = data.token, endpoint = data.endpoint }
			self:wake()
		end
	end)

	return self
end

type VoiceStateFact = { channelId: string?, sessionId: string }
type ServerFact = { token: string, endpoint: string? }
type DropCause =
	"closed"
	| "zombie"
	| "openFailed"
	| "handshakeFailed"
	| "badKey"
	| "heartbeatFailed"
	| "reconnectRequested"
type DropFact = { cause: DropCause, code: number?, detail: string? }
type Facts = { voiceStates: { VoiceStateFact }, server: ServerFact?, drop: DropFact?, ready: boolean }
type Timer = { expired: boolean, thread: thread? }
type AttemptOutcome = "ready" | "failed" | "closed"
type SignalOutcome = "signalled" | "failed" | "closed"

export type Status = "idle" | "signalling" | "connecting" | "ready" | "resuming" | "disconnected" | "closed"
export type CloseReason = "left" | "removed" | "joinTimedOut" | "gaveUp" | "rejected" | "shardDown"

export type Connection = typeof(Connection.Prototype) & {
	webSocket: voiceWebsocket.WebSocketTransport,
	udp: voiceUdp.UdpTransport,
	rtp: voiceRtpCrypto.RtpCrypto,
	dave: voiceDaveManager.DaveManager,

	jitters: { [number]: voiceJitter.Jitter },

	shard: websocket.Shard,
	guildId: string,
	channelId: string,
	userId: string,
	sessionId: string,
	token: secret.Secret<string>,
	endpoint: string,

	status: Status,
	generation: number,
	announcedGeneration: number,
	lastConnectResumed: boolean,
	closeReason: CloseReason?,
	closeDetail: string,
	recoveryAttempts: number,
	voiceRequested: boolean,
	readyShardSessionId: string?,
	pendingVoiceStates: { VoiceStateFact },
	pendingServer: ServerFact?,
	pendingDrop: DropFact?,
	readySignalled: boolean,
	dispatchDisconnect: (() -> ())?,
	recentServer: ServerFact?,
	recentServerTimer: Timer?,
	lastFailure: string,
	decodeAudio: boolean,

	onConnected: emitter.Emitter<()>,
	onDisconnected: emitter.Emitter<number?, boolean?>,
	onReady: emitter.Emitter<()>,
	onClosed: emitter.Emitter<CloseReason, number?>,
	onResumed: emitter.Emitter<()>,
	onWake: emitter.Emitter<()>,
	onHeartbeat: emitter.Emitter<number?>,
	onRawMessage: emitter.Emitter<apiTypes.Payload<unknown>>,
	onSpeaking: emitter.Emitter<{ userId: string, ssrc: number, speaking: number }>,
	onClientConnect: emitter.Emitter<{ userId: string }>,
	onClientDisconnect: emitter.Emitter<{ userId: string }>,
	onDaveEpochTransition: emitter.Emitter<number>,
	onMediaReady: emitter.Emitter<()>,
	onRawAudioFrame: emitter.Emitter<{ userId: string?, ssrc: number, frame: buffer }>,
	onAudioFrame: emitter.Emitter<{ userId: string?, ssrc: number, frame: buffer }>,

	logger: logger.Logger,
}

return Connection.Interface
