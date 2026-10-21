--[=[
	@class DiscordStub.WebsocketServer
	@__index Prototype

	A localhost gateway: Hello on open, ACK on heartbeat, a new session on Identify, replay and RESUMED on Resume, and
	whatever the handler returns. Every connection is dialled by URL, so the library's own shard code speaks to it
	unchanged, and every upgrade and payload is recorded for the test to assert on.
]=]

--[=[
	@prop clock Clock
	@within DiscordStub.WebsocketServer
	The world clock: upgrade delays wait on it and received records are stamped with it.
]=]

--[=[
	@prop handler Handler?
	@within DiscordStub.WebsocketServer
	The test's handler, which answers every payload before the default replies.
]=]

--[=[
	@prop onStop function?
	@within DiscordStub.WebsocketServer
	Called with the handle after it stops.
]=]

--[=[
	@prop connections { Connection }
	@within DiscordStub.WebsocketServer
	Every connection ever opened, in open order; a closed one stays with `open = false`.
]=]

--[=[
	@prop server any?
	@within DiscordStub.WebsocketServer
	The Zune server handle, nil after it stops.
]=]

--[=[
	@prop port number
	@within DiscordStub.WebsocketServer
	The ephemeral port the server bound to.
]=]

--[=[
	@prop url string
	@within DiscordStub.WebsocketServer
	The server's base URL, `ws://127.0.0.1:{port}`.
]=]

--[=[
	@prop heartbeatIntervalMilliseconds number
	@within DiscordStub.WebsocketServer
	The interval the default Hello announces, 41250 like Discord's.
]=]

--[=[
	@prop connectAttempts number
	@within DiscordStub.WebsocketServer
	Every upgrade request the server has seen, refused ones included.
]=]

--[=[
	@prop refuseUpgrades number
	@within DiscordStub.WebsocketServer
	How many of the next upgrades to refuse; each refusal fails the client with `UpgradeFailed`.
]=]

--[=[
	@prop upgradeDelaySeconds number
	@within DiscordStub.WebsocketServer
	Clock seconds each upgrade is held before it is answered, 0 for none.
]=]

--[=[
	@prop handshaking boolean
	@within DiscordStub.WebsocketServer
	True while an upgrade is held by `upgradeDelaySeconds`.
]=]

--[=[
	@prop pendingPaths { string }
	@within DiscordStub.WebsocketServer
	Paths of accepted upgrades whose connection has not opened yet, oldest first.
]=]

--[=[
	@prop sequence number
	@within DiscordStub.WebsocketServer
	The last dispatch sequence number the world handed out.
]=]

--[=[
	@prop sessionId string?
	@within DiscordStub.WebsocketServer
	The current session, `stub-session-{identifyCount}`, nil before the first Identify.
]=]

--[=[
	@prop dispatchLog { Payload }
	@within DiscordStub.WebsocketServer
	The current session's dispatches other than READY and RESUMED, which a Resume replays.
]=]

--[=[
	@prop identifyCount number
	@within DiscordStub.WebsocketServer
	How many Identify payloads the default reply has answered.
]=]

--[=[
	@prop handlerErrors { string }
	@within DiscordStub.WebsocketServer
	Every error the handler raised, which Zune would otherwise print and swallow.
]=]

local stdPolyfills = require("../luau_packages/std_polyfills")
local apiTypes = require("../luau_packages/api_types")

local clock = require("./clock")
local gatewayConnection = require("./connection")
local loopback = require("./loopback")

local WebsocketServer = {}

WebsocketServer.Interface = {}
WebsocketServer.Prototype = {}

local function readyPayload(sequence: number, sessionId: string, resumeGatewayUrl: string): Payload
	return {
		op = apiTypes.gateway.opcodes.Dispatch,
		t = "READY",
		s = sequence,
		d = {
			v = 10,
			user = {
				id = "1",
				username = "Stub",
				discriminator = "0",
				global_name = "Stub",
				bot = true,
			},
			guilds = {},
			session_id = sessionId,
			resume_gateway_url = resumeGatewayUrl,
			application = {
				id = "2",
				name = "Stub",
				description = "",
				bot_public = true,
				bot_require_code_grant = false,
				verify_key = "",
				flags = 0,
			},
		},
	}
end

local function findConnection(connections: { Connection }, socket: ZuneSocket): Connection?
	for _, connection in connections do
		if connection.socket == socket then
			return connection
		end
	end

	return
end

--[=[
	@within DiscordStub.WebsocketServer

	Sends one payload to every open connection.
]=]
function WebsocketServer.Prototype.send(self: WebsocketServer, payload: Payload)
	for _, connection in self.connections do
		if connection.open then
			connection:send(payload)
		end
	end
end

--[=[
	@within DiscordStub.WebsocketServer

	Closes every open connection with `code` (1000 by default).
]=]
function WebsocketServer.Prototype.close(self: WebsocketServer, code: number?)
	for _, connection in self.connections do
		if connection.open then
			connection:close(code)
		end
	end
end

--[=[
	@within DiscordStub.WebsocketServer

	Logs a dispatch the client never received, under the next sequence number, so a later Resume replays it.
]=]
function WebsocketServer.Prototype.missDispatch(self: WebsocketServer, eventName: string, data: any)
	local sequence = self.sequence + 1

	self.sequence = sequence

	table.insert(self.dispatchLog, {
		op = apiTypes.gateway.opcodes.Dispatch,
		t = eventName,
		s = sequence,
		d = data,
	})
end

--[=[
	@within DiscordStub.WebsocketServer

	Logs a dispatch as `missDispatch` does, then sends it to every open connection bound to the current session.
]=]
function WebsocketServer.Prototype.dispatch(self: WebsocketServer, eventName: string, data: any)
	self:missDispatch(eventName, data)

	local payload = self.dispatchLog[#self.dispatchLog]

	for _, connection in self.connections do
		if connection.open and self.sessionId and connection.sessionId == self.sessionId then
			connection:send(payload)
		end
	end
end

--[=[
	@within DiscordStub.WebsocketServer

	The most recently opened connection, nil before the first.
]=]
function WebsocketServer.Prototype.latestConnection(self: WebsocketServer): Connection?
	return self.connections[#self.connections]
end

--[=[
	@within DiscordStub.WebsocketServer

	How many connections the server has not yet seen close.
]=]
function WebsocketServer.Prototype.openConnections(self: WebsocketServer): number
	local count = 0

	for _, connection in self.connections do
		if connection.open then
			count += 1
		end
	end

	return count
end

--[=[
	@within DiscordStub.WebsocketServer

	Returns the records of every received payload with `opcode` across all connections, in the order they arrived.
]=]
function WebsocketServer.Prototype.receivedOps(self: WebsocketServer, opcode: number): { Received }
	local found = {}

	for _, connection in self.connections do
		for _, record in connection:receivedOps(opcode) do
			table.insert(found, record)
		end
	end

	table.sort(found, function(left, right)
		return left.at < right.at
	end)

	return found
end

--[=[
	@within DiscordStub.WebsocketServer
	@private

	Answers one upgrade request: counts it, holds it for `upgradeDelaySeconds`, then refuses it while
	`refuseUpgrades` lasts or queues its path for the connection that opens next.
]=]
function WebsocketServer.Prototype._upgrade(self: WebsocketServer, request: ZuneRequest): boolean
	local path = if #request.path > 1 and string.sub(request.path, -1) == "/"
		then string.sub(request.path, 1, -2)
		else request.path

	self.connectAttempts += 1

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
	@within DiscordStub.WebsocketServer
	@private

	Records a newly opened socket as a connection on the oldest queued path and sends it Hello.
]=]
function WebsocketServer.Prototype._open(self: WebsocketServer, socket: ZuneSocket)
	local connection = gatewayConnection.new({
		index = #self.connections + 1,
		path = table.remove(self.pendingPaths, 1) or "?",
		socket = socket,
	})

	table.insert(self.connections, connection)

	connection:send({
		op = apiTypes.gateway.opcodes.Hello,
		d = { heartbeat_interval = self.heartbeatIntervalMilliseconds },
	})
end

--[=[
	@within DiscordStub.WebsocketServer
	@private

	Marks the socket's connection closed with the code the server saw.
]=]
function WebsocketServer.Prototype._closed(self: WebsocketServer, socket: ZuneSocket, code: number)
	local connection = findConnection(self.connections, socket)

	if not connection then
		return
	end

	connection.open = false
	connection.closeCode = code
end

--[=[
	@within DiscordStub.WebsocketServer
	@private

	Answers one message: records it on its connection, lets the handler answer it, then falls through to the default
	replies when the handler returned nil. A handler error is kept in `handlerErrors` and nothing is sent.
]=]
function WebsocketServer.Prototype._handleMessage(self: WebsocketServer, connection: Connection, message: string)
	local decoded, payload = pcall(function(): Payload
		local value = stdPolyfills.serde.decode("json" :: "json", message)
		assert(type(value) == "table" and type(value.op) == "number", "expected a gateway payload")

		return value
	end)

	if not decoded then
		return
	end

	table.insert(connection.received, { payload = payload, at = self.clock:now() })

	local handled, response = pcall(function(): (Payload | false)?
		return if self.handler then self.handler(connection, payload) else nil
	end)

	if not handled then
		table.insert(self.handlerErrors, tostring(response))

		return
	end

	if response == false then
		return
	end

	if response then
		-- the old type solver refines the excluded `false` to `true` here, so the narrowing needs the cast
		connection:send(response :: Payload)

		return
	end

	if payload.op == apiTypes.gateway.opcodes.Heartbeat then
		connection:send({ op = apiTypes.gateway.opcodes.HeartbeatACK })
	elseif payload.op == apiTypes.gateway.opcodes.Identify then
		self:_answerIdentify(connection)
	elseif payload.op == apiTypes.gateway.opcodes.Resume then
		self:_answerResume(connection, payload)
	end
end

--[=[
	@within DiscordStub.WebsocketServer
	@private

	Starts a new session for an Identify: clears the dispatch log, binds the connection and sends it READY, which is
	never logged.
]=]
function WebsocketServer.Prototype._answerIdentify(self: WebsocketServer, connection: Connection)
	local identifyCount = self.identifyCount + 1
	local sessionId = `stub-session-{identifyCount}`
	local sequence = self.sequence + 1

	self.identifyCount = identifyCount
	self.sessionId = sessionId
	self.sequence = sequence
	self.dispatchLog = {}
	connection.sessionId = sessionId

	connection:send(readyPayload(sequence, sessionId, `{self.url}/resume`))
end

--[=[
	@within DiscordStub.WebsocketServer
	@private

	Resumes the current session: binds the connection, replays every logged dispatch after the client's `seq` in
	order, then sends RESUMED, which is never logged. Any other session id is answered with `{ op = 9, d = false }`.
]=]
function WebsocketServer.Prototype._answerResume(self: WebsocketServer, connection: Connection, payload: Payload)
	local data = payload.d or {}
	local lastSequence = data.seq or 0
	local sequence = self.sequence + 1

	if not self.sessionId or data.session_id ~= self.sessionId then
		connection:send({ op = apiTypes.gateway.opcodes.InvalidSession, d = false })

		return
	end

	self.sequence = sequence
	connection.sessionId = self.sessionId

	for _, entry in self.dispatchLog do
		if (entry.s or 0) > lastSequence then
			connection:send(entry)
		end
	end

	connection:send({
		op = apiTypes.gateway.opcodes.Dispatch,
		t = "RESUMED",
		s = sequence,
		d = {},
	})
end

--[=[
	@within DiscordStub.WebsocketServer

	Stops listening, closing every open connection first. Safe to call twice.
]=]
function WebsocketServer.Prototype.stop(self: WebsocketServer)
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
	@within DiscordStub.WebsocketServer

	Creates and starts the server on `127.0.0.1` with an ephemeral port.
]=]
function WebsocketServer.Interface.new(settings: {
	clock: clock.Clock,
	handler: Handler?,
	onStop: ((server: WebsocketServer) -> ())?,
}): WebsocketServer
	local self = setmetatable(
		{
			clock = settings.clock,
			handler = settings.handler,
			onStop = settings.onStop,
			connections = {},
			port = 0,
			url = "",
			heartbeatIntervalMilliseconds = 41250,
			connectAttempts = 0,
			refuseUpgrades = 0,
			upgradeDelaySeconds = 0,
			handshaking = false,
			pendingPaths = {},
			sequence = 0,
			dispatchLog = {},
			identifyCount = 0,
			handlerErrors = {},
		} :: WebsocketServer,
		{ __index = WebsocketServer.Prototype }
	)
	local server = loopback.serve({
		request = function()
			return loopback.notFoundResponse()
		end,
		websocket = {
			upgrade = function(request)
				return self:_upgrade(request)
			end,
			open = function(socket)
				self:_open(socket)
			end,
			message = function(socket, message)
				local connection = findConnection(self.connections, socket)

				if connection then
					self:_handleMessage(connection, message)
				end
			end,
			close = function(socket, code)
				self:_closed(socket, code)
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
type Received = gatewayConnection.Received

export type Payload = gatewayConnection.Payload

export type Handler = (connection: Connection, payload: Payload) -> (Payload | false)?

export type WebsocketServer = typeof(WebsocketServer.Prototype) & {
	clock: clock.Clock,
	handler: Handler?,
	onStop: ((server: WebsocketServer) -> ())?,
	connections: { Connection },
	server: ZuneServer?,
	port: number,
	url: string,
	heartbeatIntervalMilliseconds: number,
	connectAttempts: number,
	refuseUpgrades: number,
	upgradeDelaySeconds: number,
	handshaking: boolean,
	pendingPaths: { string },
	sequence: number,
	sessionId: string?,
	dispatchLog: { Payload },
	identifyCount: number,
	handlerErrors: { string },
}

return WebsocketServer.Interface
