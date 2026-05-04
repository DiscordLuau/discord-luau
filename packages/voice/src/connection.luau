local stdPolyfills = require("../luau_packages/std_polyfills")

local emitter = require("../luau_packages/emitter")
local future = require("../luau_packages/future")
local logger = require("../luau_packages/logger")
local secret = require("../luau_packages/secret")
local util = require("../luau_packages/util")
local websocket = require("../luau_packages/websocket")
local apiTypes = require("../luau_packages/api_types")
local dave = require("../luau_packages/dave")

local voiceWebsocket = require("./websocket")
local voiceUdp = require("./udp")
local voiceRtpCrypto = require("./rtp")
local voiceDaveManager = require("./dave")
local voiceJitter = require("./jitter")

local ENCRYPTION_MODE_AES256_GCM = "aead_aes256_gcm_rtpsize"
local ENCRYPTION_MODE_XCHACHA20 = "aead_xchacha20_poly1305_rtpsize"

--[=[
	@class Voice.Connection
	@__index Prototype

	Coordinates a full Discord voice connection. Owns four sub-components:

	- `webSocket` - WebSocket lifecycle and heartbeating
	- `udp` - UDP socket, keepalive, and RTP audio send/receive
	- `rtp` - RTP encryption and sequence/timestamp/nonce counters
	- `dave` - DAVE E2EE MLS session and per-user key rotation

	Connection handles voice signalling (Identify, Resume, SelectProtocol, Speaking), opcode
	dispatch, jitter buffering per SSRC, and gateway shard integration.

	Consumer-facing events: `onReady`, `onSpeaking`, `onClientConnect`, `onClientDisconnect`,
	`onDaveEpochTransition`, `onRawAudioFrame`, `onAudioFrame`.
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
]=]

--[=[
	@prop onRawAudioFrame emitter.Emitter<{ userId: string?, ssrc: number, frame: buffer }>
	@within Voice.Connection

	Fires for each decoded audio frame before Opus decoding. `frame` is the fully decrypted
	RTP packet (12-byte RTP header + Opus payload) with all encryption layers (DAVE E2EE and
	RTP encryption) already removed. Wire-level ciphertext is never exposed.
]=]

--[=[
	@prop onAudioFrame emitter.Emitter<{ userId: string?, ssrc: number, frame: buffer }>
	@within Voice.Connection
]=]

--[=[
	@prop logger logger.Logger
	@within Voice.Connection
]=]

local Connection = {}

Connection.Interface = {}
Connection.Prototype = {}

--[=[
	@within Voice.Connection
	@private

	Tears down all session state: DAVE, UDP, all jitter buffers, and RTP counters.
]=]
function Connection.Prototype._cleanupSession(self: Connection)
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

	Opens the voice WebSocket connection. Session state is preserved when resuming.
]=]
function Connection.Prototype.connectAsync(self: Connection)
	return future.Future.new(function()
		assert(not self.webSocket.socketActive, `Voice connection is already active.`)

		if self.webSocket.isResuming then
			self.logger:debug(`skipping session cleanup for resume attempt`)
		else
			self:_cleanupSession()
		end

		local url = self.endpoint

		if not string.find(url, "^wss://") then
			url = `wss://{url}`
		end

		if not string.find(url, "%?v=") then
			url = `{url}/?v=8`
		end

		self.logger:info(`connecting to voice WebSocket: {url}`)

		self.webSocket:_openSocket(url)
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Voice.Connection

	Closes the voice WebSocket connection with an optional close code.
]=]
--[=[
	@within Voice.Connection

	Synchronously closes the voice connection and cleans up all session state. Safe to call from
	a signal handler or any context where yielding is not permitted.
]=]
function Connection.Prototype.forceClose(self: Connection, code: number?)
	self.logger:info(`voice force close: {code or 0}`)
	self.webSocket:forceClose(code)
	if not self.webSocket.isResuming then
		self:_cleanupSession()
	end
end

function Connection.Prototype.disconnectAsync(self: Connection, code: number?)
	return future.Future.new(function()
		self.logger:info(`voice disconnect requested: {code or 0}`)
		self:forceClose(code)
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Voice.Connection

	Disconnects and reconnects the voice WebSocket. Concurrent reconnect attempts are rejected.
]=]
function Connection.Prototype.reconnectAsync(self: Connection)
	return future.Future.new(function()
		if self.webSocket.socketReconnecting then
			self.logger:error(`voice connection is already reconnecting - rejecting request!`)
			return
		end

		self.webSocket.socketReconnecting = true

		self.logger:notice(`voice reconnect requested..`)

		local disconnect = self:disconnectAsync(1012):await()

		if disconnect:isOk() then
			local connect = self:connectAsync():await()

			if connect:isOk() then
				self.logger:notice(`voice reconnect successful`)
			else
				self.logger:critical(`voice reconnect failed: {connect:unwrapErr()}`)
			end
		else
			self.logger:critical(`voice disconnect before reconnect failed: {disconnect:unwrapErr()}`)
		end

		self.webSocket.socketReconnecting = false
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Voice.Connection

	Sends a VOICE_STATE_UPDATE to the gateway shard to request a voice server for this channel.
]=]
function Connection.Prototype.requestVoiceAsync(self: Connection)
	return future.Future.new(function()
		self.logger:info(`requesting voice server via gateway shard`)

		local payload = stdPolyfills.serde.encode("json" :: any, {
			op = apiTypes.gateway.opcodes.VoiceStateUpdate,
			d = {
				guild_id = if self.guildId ~= "" then self.guildId else nil,
				channel_id = self.channelId,
				self_mute = false,
				self_deaf = false,
			},
		}, true)

		self.shard
			:sendAsync(payload)
			:after(function(result)
				if result:isErr() then
					self.logger:warn(`VOICE_STATE_UPDATE send failed: {result:unwrapErr()}`)
				end
			end)
			:await()
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Voice.Connection
	@private

	Sends the voice Identify payload to the voice gateway after the WebSocket connects.
]=]
function Connection.Prototype.identifyAsync(self: Connection)
	return future.Future.new(function()
		self.logger:info(`sending voice identify`)

		self:sendAsync(stdPolyfills.serde.encode("json" :: any, {
			op = apiTypes.voice.opcodes.Identify,
			d = {
				server_id = self.guildId,
				user_id = self.userId,
				session_id = self.sessionId,
				token = self.token.value,
				max_dave_protocol_version = dave.sys.lib.daveMaxSupportedProtocolVersion(),
			},
		}, true))
			:after(function(result)
				if result:isErr() then
					self.logger:warn(`identify send failed: {result:unwrapErr()}`)
				end
			end)
			:await()
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

		self:sendAsync(stdPolyfills.serde.encode("json" :: any, {
			op = apiTypes.voice.opcodes.Resume,
			d = {
				server_id = self.guildId,
				session_id = self.sessionId,
				token = self.token.value,
			},
		}, true))
			:after(function(result)
				if result:isErr() then
					self.logger:warn(`resume send failed: {result:unwrapErr()}`)
				end
			end)
			:await()
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

		self:sendAsync(stdPolyfills.serde.encode("json" :: any, {
			op = apiTypes.voice.opcodes.SelectProtocol,
			d = {
				protocol = "udp",
				data = {
					address = externalIp,
					port = externalPort,
					mode = mode,
				},
			},
		}, true))
			:after(function(result)
				if result:isErr() then
					self.logger:warn(`select protocol send failed: {result:unwrapErr()}`)
				end
			end)
			:await()
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Voice.Connection

	Sets the bot's speaking state. Pass a bitmask of speaking flags (Microphone = 1, Soundshare = 2, Priority = 4).
]=]
function Connection.Prototype.setSpeakingAsync(self: Connection, speakingFlags: number)
	return future.Future.new(function()
		self:sendAsync(stdPolyfills.serde.encode("json" :: any, {
			op = apiTypes.voice.opcodes.Speaking,
			d = {
				speaking = speakingFlags,
				delay = 0,
				ssrc = self.udp.ssrc,
			},
		}, true))
			:after(function(result)
				if result:isErr() then
					self.logger:warn(`set speaking send failed: {result:unwrapErr()}`)
				end
			end)
			:await()
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Voice.Connection

	Encrypts and sends a raw Opus audio frame over UDP.
]=]
function Connection.Prototype.sendOpusAsync(self: Connection, audioFrame: buffer)
	return self.udp:sendOpusAsync(audioFrame, self.rtp, self.dave.daveEncryptor)
end

--[=[
	@within Voice.Connection
	@private

	Responsible for constructing this class.
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
			sessionId = settings.shard.sessionId or "",
			token = secret.new(""),
			endpoint = "",

			onConnected = emitter.new(),
			onDisconnected = emitter.new(),
			onReady = emitter.new(),
			onHeartbeat = emitter.new(),
			onRawMessage = emitter.new(),
			onSpeaking = emitter.new(),
			onClientConnect = emitter.new(),
			onClientDisconnect = emitter.new(),
			onDaveEpochTransition = emitter.new(),
			onRawAudioFrame = emitter.new(),
			onAudioFrame = emitter.new(),

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
		self:reconnectAsync():poll()
	end

	self.udp.decryptPacket = function(rawPacket: buffer): buffer?
		if not self.rtp.secretKey then
			return nil
		end

		local ok, result =
			pcall(self.rtp.decryptRtp, self.rtp, rawPacket, self.dave.ssrcToUserId, self.dave.daveDecryptors)

		if not ok then
			self.logger:warn(`RTP decrypt failed (packet={buffer.len(rawPacket)}B): {result}`)

			return nil
		end

		return result
	end

	self.udp.onAudioPacket = function(ssrc: number, sequence: number, audioFrame: buffer)
		local jitter = self.jitters[ssrc]

		if not jitter then
			local newJitter = voiceJitter.new(sequence)
			
			jitter = newJitter
			self.jitters[ssrc] = jitter

			newJitter:start(
				function(sequence: number, packet: buffer)
					self.onRawAudioFrame:invoke({ userId = self.dave.ssrcToUserId[ssrc], ssrc = ssrc, frame = packet })
				end,
				function(pcm: buffer)
					self.onAudioFrame:invoke({ userId = self.dave.ssrcToUserId[ssrc], ssrc = ssrc, frame = pcm })
				end
			)
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

			util.coroutineRun(function()
				local result = self.webSocket:heartbeatAsync(true):await()

				if result:isOk() then
					self.webSocket:heartbeatIn(self.webSocket.heartbeatInterval :: number)
				else
					self.logger:critical(`initial voice heartbeat failed: {result:unwrapErr()}`)
					self:disconnectAsync(1011):poll()
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

			util.coroutineRun(function()
				local discoveryResult = self.udp:discoverIpAsync():await()

				if discoveryResult:isErr() then
					self.logger:warn(`UDP IP discovery failed: {discoveryResult:unwrapErr()}`)
					return
				end

				local externalIp, externalPort = discoveryResult:unwrapOk()

				local selectedMode = ENCRYPTION_MODE_XCHACHA20

				for _, mode in next, self.udp.modes or {} do
					if mode == ENCRYPTION_MODE_AES256_GCM then
						selectedMode = mode
						break
					elseif mode == ENCRYPTION_MODE_XCHACHA20 then
						selectedMode = mode
						break
					end
				end

				local selectResult = self:selectProtocolAsync(externalIp, externalPort, selectedMode):await()

				if selectResult:isErr() then
					self.logger:warn(`select protocol failed: {selectResult:unwrapErr()}`)
				end
			end)

		elseif opcode == apiTypes.voice.opcodes.SessionDescription then
			local confirmedMode = payloadData.mode
			local secretKeyArray = payloadData.secret_key
			local daveProtocolVersion = payloadData.dave_protocol_version

			self.logger:info(`received voice SessionDescription, mode={confirmedMode}`)

			if self.rtp.encryptionMode and confirmedMode ~= self.rtp.encryptionMode then
				self.logger:warn(
					`SessionDescription mode '{confirmedMode}' differs from negotiated '{self.rtp.encryptionMode}', updating`
				)
			end

			self.rtp.encryptionMode = confirmedMode

			if secretKeyArray then
				local secretKey = buffer.create(#secretKeyArray)

				for i, byte in secretKeyArray do
					buffer.writeu8(secretKey, i - 1, byte)
				end

				self.rtp.secretKey = secretKey
			else
				self.logger:debug(`no secret_key in SessionDescription payload`)
			end

			if daveProtocolVersion and daveProtocolVersion > 0 and not self.dave.daveSession then
				self.logger:debug(`SessionDescription indicates DAVE v{daveProtocolVersion}, initialising session`)
				self.dave:initSession(daveProtocolVersion, self.channelId, self.userId)
				self.logger:debug(
					`DAVE session initialised from protocol={daveProtocolVersion} group={self.channelId} user={self.userId}`
				)
			end

			self.onReady:invoke()

		elseif opcode == apiTypes.voice.opcodes.Resumed then
			self.webSocket.isResuming = false

			self.logger:notice(`voice session resumed successfully`)

			self.onReady:invoke()

		elseif opcode == apiTypes.voice.opcodes.ClientsConnect then
			self.dave.recognizedUserIds = payloadData.user_ids

			self.logger:info(`received voice channel members: {#self.dave.recognizedUserIds} user(s)`)

			for _, userId in self.dave.recognizedUserIds do
				self.onClientConnect:invoke({ userId = userId })
			end

		elseif opcode == apiTypes.voice.opcodes.Speaking then
			self.dave.ssrcToUserId[payloadData.ssrc] = payloadData.user_id

			self.onSpeaking:invoke({ userId = payloadData.user_id, ssrc = payloadData.ssrc, speaking = payloadData.speaking })

		elseif opcode == apiTypes.voice.opcodes.Video then
			self.logger:debug(`received voice Video: user={payloadData.user_id} ssrc={payloadData.video_ssrc}`)

		elseif opcode == apiTypes.voice.opcodes.ClientDisconnect then
			self.logger:info(`received ClientDisconnect: user={payloadData.user_id}`)

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
			local frame = self.dave:handlePrepareTransition(payloadData)

			util.coroutineRun(function()
				self.webSocket:sendAsync(frame):await()
			end)

		elseif opcode == apiTypes.voice.opcodes.DaveProtocolExecuteTransition then
			self.dave:handleExecuteTransition(payloadData)

		elseif opcode == apiTypes.voice.opcodes.DaveProtocolTransitionReady then
			self.logger:info(`DAVE protocol transition ready (server ack)`)

		elseif opcode == apiTypes.voice.opcodes.DaveProtocolPrepareEpoch then
			self.dave:handlePrepareEpoch(payloadData, self.channelId, self.userId)

		elseif opcode == apiTypes.voice.opcodes.DaveMlsExternalSenderPackage then
			local frame = self.dave:handleExternalSender(payloadData)

			if frame then
				util.coroutineRun(function()
					self.webSocket:sendAsync(frame):await()
				end)
			end

		elseif opcode == apiTypes.voice.opcodes.DaveMlsProposals then
			local frame, rosterIds = self.dave:handleProposals(payloadData, self.userId, self.udp.ssrc)

			if frame and rosterIds then
				self.onDaveEpochTransition:invoke(#rosterIds)

				util.coroutineRun(function()
					self.webSocket:sendAsync(frame):await()
				end)
			end

		elseif opcode == apiTypes.voice.opcodes.DaveMlsAnnounceCommitTransition then
			local rosterIds = self.dave:handleCommitTransition(payloadData, self.userId, self.udp.ssrc)

			if rosterIds then
				self.onDaveEpochTransition:invoke(#rosterIds)
			end

		elseif opcode == apiTypes.voice.opcodes.DaveMlsWelcome then
			local rosterIds = self.dave:handleWelcome(payloadData, self.userId, self.udp.ssrc)

			if rosterIds then
				self.onDaveEpochTransition:invoke(#rosterIds)
			end

		elseif opcode == apiTypes.voice.opcodes.DaveMlsInvalidCommitWelcome then
			self.logger:warn(`received DAVE MLS invalid commit welcome`)
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
			self.logger:critical(`voice {if isResuming then "resume" else "identify"} failed: {result:unwrapErr()}`)
		end
	end)

	self.onDisconnected:listen(function(code: number?, closedBySelf: boolean?)
		if closedBySelf then
			return
		end

		if self.webSocket.heartbeatThread then
			coroutine.close(self.webSocket.heartbeatThread)

			self.webSocket.heartbeatThread = nil
		end

		if self.webSocket.isResuming then
			self.webSocket.isResuming = false

			self.logger:warn(`voice resume attempt failed (close code={tostring(code)}), performing full reconnect`)

			self:reconnectAsync():poll()

			return
		end

		if code == apiTypes.voice.closeCodes.SessionNoLongerValid then
			self.logger:warn(`voice session no longer valid, a fresh VOICE_SERVER_UPDATE is required`)
		elseif code == apiTypes.voice.closeCodes.Disconnected then
			self.logger:warn(`removed from voice channel`)
		elseif code == apiTypes.voice.closeCodes.DisconnectedRateLimited then
			self.logger:warn(`voice disconnected: rate limited`)
		elseif code == apiTypes.voice.closeCodes.DisconnectedCallTerminated then
			self.logger:warn(`voice disconnected: call terminated`)
		elseif code == apiTypes.voice.closeCodes.DaveProtocolRequired then
			self.logger:error(`voice channel requires DAVE E2EE support`)
		elseif code == apiTypes.voice.closeCodes.VoiceServerCrashed then
			self.logger:warn(`voice server crashed, attempting resume..`)
			self.webSocket.isResuming = true
			self:reconnectAsync():poll()
		elseif code == -1 then
			if self.webSocket.socketReconnecting then
				return
			end

			self.logger:warn(`voice socket closed without a close code, attempting resume..`)
			self.webSocket.isResuming = true
			self:reconnectAsync():poll()
		else
			self.logger:warn(`unknown voice close code: {code}, reconnecting..`)
			self:reconnectAsync():poll()
		end
	end)

	self.onReady:listen(function()
		self.udp:_startUdpReceiveLoop()
		self.udp:_startKeepaliveLoop()
	end)

	settings.shard.onSocketDispatch:listen(function(payload: any)
		if
			payload.t == apiTypes.gateway.receiveEvents.VoiceStateUpdate
			and payload.d.user_id == self.userId
			and payload.d.guild_id == self.guildId
		then
			self.logger:info(`received VOICE_STATE_UPDATE, session_id={payload.d.session_id}`)
			self.sessionId = payload.d.session_id
		elseif payload.t == apiTypes.gateway.receiveEvents.VoiceServerUpdate and payload.d.guild_id == self.guildId then
			self.logger:info(`received VOICE_SERVER_UPDATE for guild {self.guildId}`)
			self.token = secret.new(payload.d.token)
			self.endpoint = payload.d.endpoint

			if self.sessionId ~= "" then
				util.coroutineRun(function()
					if self.webSocket.socketActive then
						local result = self:reconnectAsync():await()

						if result:isErr() then
							self.logger:warn(`voice server reconnect failed: {result:unwrapErr()}`)
						end
					else
						local result = self:connectAsync():await()

						if result:isErr() then
							self.logger:warn(`voice server connect failed: {result:unwrapErr()}`)
						end
					end
				end)
			end
		end
	end)

	return self
end

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

	onConnected: emitter.Emitter<()>,
	onDisconnected: emitter.Emitter<number?, boolean?>,
	onReady: emitter.Emitter<()>,
	onHeartbeat: emitter.Emitter<number?>,
	onRawMessage: emitter.Emitter<apiTypes.Payload<unknown>>,
	onSpeaking: emitter.Emitter<{ userId: string, ssrc: number, speaking: number }>,
	onClientConnect: emitter.Emitter<{ userId: string }>,
	onClientDisconnect: emitter.Emitter<{ userId: string }>,
	onDaveEpochTransition: emitter.Emitter<number>,
	onRawAudioFrame: emitter.Emitter<{ userId: string?, ssrc: number, frame: buffer }>,
	onAudioFrame: emitter.Emitter<{ userId: string?, ssrc: number, frame: buffer }>,

	logger: logger.Logger,
}

return Connection.Interface
