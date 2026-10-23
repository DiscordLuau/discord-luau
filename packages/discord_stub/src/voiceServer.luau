--[=[
	@class DiscordStub.VoiceServer
	@__index Prototype

	A localhost voice gateway speaking version 8: Hello on open, Ready on Identify, Session Description on Select
	Protocol, an ACK echoing `t` on Heartbeat, and Resumed (or close 4006) on Resume. Ready points the client at a
	`UdpServer`. Every message the client sends is recorded with its raw text or binary buffer, and the test scripts
	the rest: Speaking, Clients Connect, Client Disconnect, or any JSON or binary opcode. Tests can withhold heartbeat
	ACKs, refuse or hold upgrades (`ackHeartbeats`, `refuseUpgrades`, `upgradeDelaySeconds`).
]=]

--[=[
	@prop clock Clock
	@within DiscordStub.VoiceServer
	The world clock: received records are stamped with it and `waitForOp` polls in it.
]=]

--[=[
	@prop udpServer UdpServer
	@within DiscordStub.VoiceServer
	The UDP server whose port Ready announces.
]=]

--[=[
	@prop onStop function?
	@within DiscordStub.VoiceServer
	Called with the handle after it stops.
]=]

--[=[
	@prop server any?
	@within DiscordStub.VoiceServer
	The Zune server handle, nil after it stops.
]=]

--[=[
	@prop port number
	@within DiscordStub.VoiceServer
	The ephemeral port the server bound to.
]=]

--[=[
	@prop url string
	@within DiscordStub.VoiceServer
	The server's URL with its scheme, `ws://127.0.0.1:{port}`, which VOICE_SERVER_UPDATE carries as `endpoint`.
]=]

--[=[
	@prop connections { Connection }
	@within DiscordStub.VoiceServer
	Every connection ever opened, in open order; a closed one stays with `open = false`.
]=]

--[=[
	@prop received { Received }
	@within DiscordStub.VoiceServer
	Every message any connection sent, in arrival order: its opcode, the decoded payload, the raw text or binary
	buffer, and the clock time it arrived. A binary message decodes to `{ op = opcode, d = payload buffer }`.
]=]

--[=[
	@prop pendingPaths { string }
	@within DiscordStub.VoiceServer
	Paths of accepted upgrades whose connection has not opened yet, oldest first.
]=]

--[=[
	@prop heartbeatIntervalMilliseconds number
	@within DiscordStub.VoiceServer
	The interval Hello and Ready announce, 41250 by default.
]=]

--[=[
	@prop modes { string }
	@within DiscordStub.VoiceServer
	The encryption modes Ready offers; Select Protocol with any other mode is closed with 4016.
]=]

--[=[
	@prop daveProtocolVersion number
	@within DiscordStub.VoiceServer
	The DAVE protocol version Session Description announces, 0 (no end-to-end encryption) by default.
]=]

--[=[
	@prop token string
	@within DiscordStub.VoiceServer
	The voice token VOICE_SERVER_UPDATE hands out and a Resume must carry.
]=]

--[=[
	@prop sessionId string
	@within DiscordStub.VoiceServer
	The voice session id VOICE_STATE_UPDATE hands out and a Resume must carry.
]=]

--[=[
	@prop serverId string?
	@within DiscordStub.VoiceServer
	The `server_id` the latest Identify carried, which a Resume must match; nil before the first Identify.
]=]

--[=[
	@prop ssrc number
	@within DiscordStub.VoiceServer
	The SSRC Ready assigns, 1234 by default.
]=]

--[=[
	@prop secretKey buffer
	@within DiscordStub.VoiceServer
	The 32-byte key Session Description hands out as `secret_key`.
]=]

--[=[
	@prop selectedMode string?
	@within DiscordStub.VoiceServer
	The mode the latest accepted Select Protocol chose, nil before one.
]=]

--[=[
	@prop sequence number
	@within DiscordStub.VoiceServer
	The last sequence number the server handed out. Scripted JSON messages carry it as `seq`, and binary messages
	carry it as their 2-byte big-endian prefix.
]=]

--[=[
	@prop errors { string }
	@within DiscordStub.VoiceServer
	Every error raised while answering a message, which Zune would otherwise print and swallow.
]=]

--[=[
	@prop ackHeartbeats boolean
	@within DiscordStub.VoiceServer
	Whether a Heartbeat is answered with an ACK; true by default. False makes the client miss its ACKs.
]=]

--[=[
	@prop refuseUpgrades number
	@within DiscordStub.VoiceServer
	How many of the next upgrades to refuse; each refusal fails the client's connect with `UpgradeFailed`.
]=]

--[=[
	@prop upgradeDelaySeconds number
	@within DiscordStub.VoiceServer
	Clock seconds each upgrade is held before it is answered, 0 for none.
]=]

--[=[
	@prop handshaking boolean
	@within DiscordStub.VoiceServer
	True while an upgrade is held by `upgradeDelaySeconds`.
]=]

local stdPolyfills = require("../luau_packages/std_polyfills")
local apiTypes = require("../luau_packages/api_types")

local clock = require("./clock")
local gatewayConnection = require("./connection")
local loopback = require("./loopback")
local udpServer = require("./udpServer")

local SECRET_KEY_SIZE = 32
local BINARY_HEADER_SIZE = 3
local JSON_OPENING_BRACE = string.byte("{")

local VoiceServer = {}

VoiceServer.Interface = {}
VoiceServer.Prototype = {}

local function decodeMessage(message: string | buffer): Payload
	local bytes = zune.mem.slice(message, 0)

	assert(buffer.len(bytes) > 0, "expected a voice gateway message, got an empty one")

	if buffer.readu8(bytes, 0) ~= JSON_OPENING_BRACE then
		return { op = buffer.readu8(bytes, 0), d = zune.mem.slice(bytes, 1) }
	end

	local value = stdPolyfills.serde.decode("json", buffer.tostring(bytes))

	assert(type(value) == "table" and type(value.op) == "number", "expected a voice gateway payload")

	return value
end

--[=[
	@within DiscordStub.VoiceServer

	Sends `{ op = opcode, d = data, seq }` as JSON to every open connection under the next sequence number.
]=]
function VoiceServer.Prototype.sendJson(self: VoiceServer, opcode: number, data: any)
	local sequence = self.sequence + 1

	self.sequence = sequence
	self:broadcast(stdPolyfills.serde.encode("json", { op = opcode, d = data, seq = sequence }))
end

--[=[
	@within DiscordStub.VoiceServer

	Sends a binary message to every open connection: the next sequence number as 2 big-endian bytes, the opcode as
	1 byte, then `payload`.
]=]
function VoiceServer.Prototype.sendBinary(self: VoiceServer, opcode: number, payload: buffer)
	local sequence = self.sequence + 1
	local payloadLength = buffer.len(payload)
	local frame = buffer.create(BINARY_HEADER_SIZE + payloadLength)

	self.sequence = sequence
	buffer.writeu8(frame, 0, bit32.band(bit32.rshift(sequence, 8), 0xFF))
	buffer.writeu8(frame, 1, bit32.band(sequence, 0xFF))
	buffer.writeu8(frame, 2, opcode)
	buffer.copy(frame, BINARY_HEADER_SIZE, payload, 0, payloadLength)
	self:broadcast(frame)
end

--[=[
	@within DiscordStub.VoiceServer

	Sends Speaking (op 5) for `userId` on `ssrc` with the `speaking` flags.
]=]
function VoiceServer.Prototype.sendSpeaking(self: VoiceServer, userId: string, ssrc: number, speaking: number)
	self:sendJson(apiTypes.voice.opcodes.Speaking, { user_id = userId, ssrc = ssrc, speaking = speaking })
end

--[=[
	@within DiscordStub.VoiceServer

	Sends Clients Connect (op 11) listing `userIds`.
]=]
function VoiceServer.Prototype.sendClientsConnect(self: VoiceServer, userIds: { string })
	self:sendJson(apiTypes.voice.opcodes.ClientsConnect, { user_ids = userIds })
end

--[=[
	@within DiscordStub.VoiceServer

	Sends Client Disconnect (op 13) for `userId`.
]=]
function VoiceServer.Prototype.sendClientDisconnect(self: VoiceServer, userId: string)
	self:sendJson(apiTypes.voice.opcodes.ClientDisconnect, { user_id = userId })
end

--[=[
	@within DiscordStub.VoiceServer

	Closes every open connection with `code` (1000 by default).
]=]
function VoiceServer.Prototype.close(self: VoiceServer, code: number?)
	for _, connection in self.connections do
		if connection.open then
			connection:close(code)
		end
	end
end

--[=[
	@within DiscordStub.VoiceServer

	The opcode of every received message, in arrival order.
]=]
function VoiceServer.Prototype.receivedOps(self: VoiceServer): { number }
	local opcodes = {}

	for _, record in self.received do
		table.insert(opcodes, record.opcode)
	end

	return opcodes
end

--[=[
	@within DiscordStub.VoiceServer

	Waits up to `seconds` of clock time for a message with `opcode` to have arrived. Returns whether one did.
]=]
function VoiceServer.Prototype.waitForOp(self: VoiceServer, opcode: number, seconds: number): boolean
	return self.clock:waitFor(function()
		return table.find(self:receivedOps(), opcode)
	end, seconds)
end

--[=[
	@within DiscordStub.VoiceServer
	@private

	Sends one raw message to every open connection.
]=]
function VoiceServer.Prototype.broadcast(self: VoiceServer, message: string | buffer)
	for _, connection in self.connections do
		if connection.open then
			connection:sendRaw(message)
		end
	end
end

--[=[
	@within DiscordStub.VoiceServer
	@private

	Answers one upgrade request: holds it for `upgradeDelaySeconds`, then refuses it while `refuseUpgrades` lasts or
	queues its path for the connection that opens next.
]=]
function VoiceServer.Prototype.upgrade(self: VoiceServer, request: ZuneRequest): boolean
	local path = loopback.upgradePath(request)

	if self.upgradeDelaySeconds > 0 then
		self.handshaking = true
		self.clock:wait(self.upgradeDelaySeconds)
		self.handshaking = false
	end

	if self.refuseUpgrades > 0 then
		self.refuseUpgrades -= 1

		return false
	end

	table.insert(self.pendingPaths, path)

	return true
end

--[=[
	@within DiscordStub.VoiceServer
	@private

	Records a newly opened socket as a connection on the oldest queued path and sends it Hello.
]=]
function VoiceServer.Prototype.open(self: VoiceServer, socket: ZuneSocket)
	local connection = gatewayConnection.new({
		index = #self.connections + 1,
		path = table.remove(self.pendingPaths, 1) or "?",
		socket = socket,
	})

	table.insert(self.connections, connection)

	connection:send({
		op = apiTypes.voice.opcodes.Hello,
		d = { heartbeat_interval = self.heartbeatIntervalMilliseconds },
	})
end

--[=[
	@within DiscordStub.VoiceServer
	@private

	Marks the socket's connection closed with the code the server saw.
]=]
function VoiceServer.Prototype.closed(self: VoiceServer, socket: ZuneSocket, code: number)
	local connection = gatewayConnection.find(self.connections, socket)

	if not connection then
		return
	end

	connection.open = false
	connection.closeCode = code
end

--[=[
	@within DiscordStub.VoiceServer
	@private

	Answers one message: records it on its connection and the server, then answers Identify, Select Protocol,
	Heartbeat (an ACK echoing `t`) and Resume. A message whose first byte is `{` is JSON, as the library's own client
	decides; any other is binary, one opcode byte then the payload. A message that does not decode closes the
	connection with 4002.
]=]
function VoiceServer.Prototype.handleMessage(self: VoiceServer, connection: Connection, message: string | buffer)
	local decoded, payload = pcall(decodeMessage, message)

	if not decoded then
		connection:close(apiTypes.voice.closeCodes.FailedToDecodePayload)

		return
	end

	local record: Received = { opcode = payload.op, payload = payload, raw = message, at = self.clock:now() }

	table.insert(connection.received, record)
	table.insert(self.received, record)

	if payload.op == apiTypes.voice.opcodes.Identify then
		self:answerIdentify(connection, payload)
	elseif payload.op == apiTypes.voice.opcodes.SelectProtocol then
		self:answerSelectProtocol(connection, payload)
	elseif payload.op == apiTypes.voice.opcodes.Heartbeat and self.ackHeartbeats then
		connection:send({ op = apiTypes.voice.opcodes.HeartbeatACK, d = { t = (payload.d or {}).t } })
	elseif payload.op == apiTypes.voice.opcodes.Resume then
		self:answerResume(connection, payload)
	end
end

--[=[
	@within DiscordStub.VoiceServer
	@private

	Binds the connection to the voice session, remembers the Identify's `server_id` and sends Ready with the SSRC,
	the UDP server's address and the offered modes.
]=]
function VoiceServer.Prototype.answerIdentify(self: VoiceServer, connection: Connection, payload: Payload)
	local data = payload.d or {}

	self.serverId = data.server_id
	connection.sessionId = self.sessionId

	connection:send({
		op = apiTypes.voice.opcodes.Ready,
		d = {
			ssrc = self.ssrc,
			ip = "127.0.0.1",
			port = self.udpServer.port,
			modes = self.modes,
			heartbeat_interval = self.heartbeatIntervalMilliseconds,
		},
	})
end

--[=[
	@within DiscordStub.VoiceServer
	@private

	Sends Session Description with the chosen mode, the secret key as 32 numbers and the DAVE protocol version. A mode
	Ready did not offer closes the connection with 4016.
]=]
function VoiceServer.Prototype.answerSelectProtocol(self: VoiceServer, connection: Connection, payload: Payload)
	local data = payload.d or {}
	local protocolData = data.data or {}
	local mode = protocolData.mode
	local secretKeyBytes = {}

	if not table.find(self.modes, mode) then
		connection:close(apiTypes.voice.closeCodes.UnknownEncryptionMode)

		return
	end

	for index = 0, buffer.len(self.secretKey) - 1 do
		table.insert(secretKeyBytes, buffer.readu8(self.secretKey, index))
	end

	self.selectedMode = mode

	connection:send({
		op = apiTypes.voice.opcodes.SessionDescription,
		d = {
			mode = mode,
			secret_key = secretKeyBytes,
			dave_protocol_version = self.daveProtocolVersion,
		},
	})
end

--[=[
	@within DiscordStub.VoiceServer
	@private

	Sends Resumed when the Resume's `server_id`, `session_id` and `token` all match the session, and binds the
	connection to it; anything else closes the connection with 4006.
]=]
function VoiceServer.Prototype.answerResume(self: VoiceServer, connection: Connection, payload: Payload)
	local data = payload.d or {}

	if
		not self.serverId
		or data.server_id ~= self.serverId
		or data.session_id ~= self.sessionId
		or data.token ~= self.token
	then
		connection:close(apiTypes.voice.closeCodes.SessionNoLongerValid)

		return
	end

	connection.sessionId = self.sessionId

	connection:send({ op = apiTypes.voice.opcodes.Resumed, d = zune.serde.json.values.null })
end

--[=[
	@within DiscordStub.VoiceServer

	Stops listening, closing every open connection with 1000 first. The UDP server is left running. Safe to call
	twice.
]=]
function VoiceServer.Prototype.stop(self: VoiceServer)
	self:close(1000)

	if self.server then
		self.server:stop()
		self.server = nil
	end

	if self.onStop then
		self.onStop(self)
	end
end

--[=[
	@within DiscordStub.VoiceServer

	Creates and starts the server on `127.0.0.1` with an ephemeral port. The clock defaults to a real one.
]=]
function VoiceServer.Interface.new(settings: {
	clock: clock.Clock?,
	udpServer: udpServer.UdpServer,
	heartbeatIntervalMilliseconds: number?,
	modes: { string }?,
	daveProtocolVersion: number?,
	token: string?,
	sessionId: string?,
	onStop: ((server: VoiceServer) -> ())?,
}): VoiceServer
	local secretKey = buffer.create(SECRET_KEY_SIZE)

	for index = 0, SECRET_KEY_SIZE - 1 do
		buffer.writeu8(secretKey, index, index + 1)
	end

	local self = setmetatable(
		{
			clock = settings.clock or clock.new(),
			udpServer = settings.udpServer,
			onStop = settings.onStop,
			port = 0,
			url = "",
			connections = {},
			received = {},
			pendingPaths = {},
			heartbeatIntervalMilliseconds = settings.heartbeatIntervalMilliseconds or 41250,
			modes = settings.modes or { "aead_aes256_gcm_rtpsize", "aead_xchacha20_poly1305_rtpsize" },
			daveProtocolVersion = settings.daveProtocolVersion or 0,
			token = settings.token or "stub-voice-token",
			sessionId = settings.sessionId or "stub-voice-session",
			ssrc = 1234,
			secretKey = secretKey,
			sequence = 0,
			errors = {},
			ackHeartbeats = true,
			refuseUpgrades = 0,
			upgradeDelaySeconds = 0,
			handshaking = false,
		} :: VoiceServer,
		{ __index = VoiceServer.Prototype }
	)
	local server = loopback.serve({
		request = function()
			return loopback.notFoundResponse()
		end,
		websocket = {
			upgrade = function(request)
				return self:upgrade(request)
			end,
			open = function(socket)
				self:open(socket)
			end,
			message = function(socket, message)
				local connection = gatewayConnection.find(self.connections, socket)
				local handled, handleError = pcall(function()
					if connection then
						self:handleMessage(connection, message)
					end
				end)

				if not handled then
					table.insert(self.errors, tostring(handleError))
				end
			end,
			close = function(socket, code)
				self:closed(socket, code)
			end,
		},
	})

	self.server = server
	self.port = server:getPort()
	self.url = `ws://127.0.0.1:{self.port}`

	return self
end

type ZuneServer = HttpServer
type ZuneSocket = HttpWebSocket
type ZuneRequest = HttpServerRequest
type Connection = gatewayConnection.Connection
type Payload = gatewayConnection.Payload
type Received = gatewayConnection.Received

export type VoiceServer = typeof(VoiceServer.Prototype) & {
	clock: clock.Clock,
	udpServer: udpServer.UdpServer,
	onStop: ((server: VoiceServer) -> ())?,
	server: ZuneServer?,
	port: number,
	url: string,
	connections: { Connection },
	received: { Received },
	pendingPaths: { string },
	heartbeatIntervalMilliseconds: number,
	modes: { string },
	daveProtocolVersion: number,
	token: string,
	sessionId: string,
	serverId: string?,
	ssrc: number,
	secretKey: buffer,
	selectedMode: string?,
	sequence: number,
	errors: { string },
	ackHeartbeats: boolean,
	refuseUpgrades: number,
	upgradeDelaySeconds: number,
	handshaking: boolean,
}

return VoiceServer.Interface
