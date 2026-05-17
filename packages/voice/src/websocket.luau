local stdPolyfills = require("../luau_packages/std_polyfills")
local future = require("../luau_packages/future")
local logger = require("../luau_packages/logger")
local util = require("../luau_packages/util")
local apiTypes = require("../luau_packages/api_types")

--[=[
	@class Voice.WebSocketTransport
	@__index Prototype

	Manages the WebSocket connection to the Discord voice gateway: socket lifecycle, binary and JSON
	message framing, and heartbeating. Detects zombified connections (unacknowledged heartbeat) and
	notifies the owner via the `onZombified` callback.
]=]

--[=[
	@prop socketActive boolean
	@within Voice.WebSocketTransport
]=]

--[=[
	@prop socketReconnecting boolean
	@within Voice.WebSocketTransport
]=]

--[=[
	@prop socketDisconnecting boolean
	@within Voice.WebSocketTransport
]=]

--[=[
	@prop isResuming boolean
	@within Voice.WebSocketTransport
]=]

--[=[
	@prop socketInstance any?
	@within Voice.WebSocketTransport
]=]

--[=[
	@prop socketThread thread?
	@within Voice.WebSocketTransport
]=]

--[=[
	@prop heartbeatInterval number?
	@within Voice.WebSocketTransport
]=]

--[=[
	@prop heartbeatThread thread?
	@within Voice.WebSocketTransport
]=]

--[=[
	@prop heartbeatAcknowledged boolean
	@within Voice.WebSocketTransport
]=]

--[=[
	@prop heartbeatClockTime number?
	@within Voice.WebSocketTransport
]=]

--[=[
	@prop heartbeatPing number?
	@within Voice.WebSocketTransport
]=]

--[=[
	@prop sequenceAcknowledgement number
	@within Voice.WebSocketTransport
]=]

--[=[
	@prop onConnected (() -> ())?
	@within Voice.WebSocketTransport
]=]

--[=[
	@prop onDisconnected ((code: number?, closedBySelf: boolean?) -> ())?
	@within Voice.WebSocketTransport
]=]

--[=[
	@prop onMessage ((payload: any) -> ())?
	@within Voice.WebSocketTransport
]=]

--[=[
	@prop onZombified (() -> ())?
	@within Voice.WebSocketTransport
]=]

--[=[
	@prop logger logger.Logger
	@within Voice.WebSocketTransport
]=]

local WebSocketTransport = {}

WebSocketTransport.Interface = {}
WebSocketTransport.Prototype = {}

--[=[
	@within Voice.WebSocketTransport

	Sends a raw message over the voice WebSocket.
]=]
function WebSocketTransport.Prototype.sendAsync(self: WebSocketTransport, data: string | buffer)
	return future.Future.new(function()
		assert(self.socketActive and self.socketInstance, `Voice connection is not active.`)

		local dataLength = if type(data) == "buffer" then buffer.len(data) else string.len(data)

		self.logger:debug(`sending voice WebSocket message: #{dataLength}`)

		local success, response: string? = pcall(self.socketInstance.send, data, true)

		if not success then
			self.socketActive = false
			self.logger:warn(`voice WebSocket send error: {response}`)
		end
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Voice.WebSocketTransport

	Decodes an incoming voice gateway message and dispatches it to `onMessage`. Binary frames are
	unwrapped from the voice binary framing format; JSON payloads are decoded directly.
]=]
function WebSocketTransport.Prototype._handleMessage(self: WebSocketTransport, message: string)
	if string.byte(message, 1) ~= 123 then -- first byte is not '{' (ASCII 123), so this is a binary-framed voice message
		local messageBuffer = buffer.fromstring(message)

		local sequenceAcknowledgement =
			bit32.bor(bit32.lshift(buffer.readu8(messageBuffer, 0), 8), buffer.readu8(messageBuffer, 1))
		local opcode = buffer.readu8(messageBuffer, 2)
		local payloadLength = buffer.len(messageBuffer) - 3
		local payload = buffer.create(payloadLength)

		buffer.copy(payload, 0, messageBuffer, 3, payloadLength)

		self.logger:debug(
			`received binary voice opcode={opcode} seq={sequenceAcknowledgement} payload={payloadLength}B`
		)

		if self.onMessage then
			self.onMessage({ op = opcode, d = payload, seq = sequenceAcknowledgement } :: any)
		end
	else
		local ok, payload = pcall(stdPolyfills.serde.decode, "json" :: any, message)

		if not ok then
			self.logger:error(`failed to decode voice WebSocket message: {payload}`)
			return
		end

		self.logger:debug(`received regular voice op {payload.op}`)

		if self.onMessage then
			self.onMessage(payload)
		end
	end
end

--[=[
	@within Voice.WebSocketTransport

	Sends a voice heartbeat. If the previous heartbeat was never acknowledged the connection is marked
	as zombified and `onZombified` is fired instead.
]=]
function WebSocketTransport.Prototype.heartbeatAsync(self: WebSocketTransport, requested: boolean?)
	return future.Future.new(function()
		if not self.heartbeatAcknowledged and not requested then
			self.logger:warn(`voice WebSocket has become zombified, reconnecting..`)

			if self.onZombified then
				self.onZombified()
			end

			return
		end

		self.heartbeatClockTime = os.clock()
		self.heartbeatAcknowledged = false

		self.logger:info(`sending voice heartbeat`)

		self:sendAsync(stdPolyfills.serde.encode("json" :: any, {
			op = apiTypes.voice.opcodes.Heartbeat,
			d = {
				t = math.floor(os.clock() * 1000),
				seq_ack = self.sequenceAcknowledgement,
			},
		}, true))
			:after(function(result)
				if result:isErr() then
					self.logger:warn(`heartbeat send failed: {result:unwrapErr()}`)
				end
			end)
			:await()
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Voice.WebSocketTransport

	Schedules the next heartbeat to fire after the given number of milliseconds, cancelling any pending heartbeat.
]=]
function WebSocketTransport.Prototype.heartbeatIn(self: WebSocketTransport, milliseconds: number)
	if self.heartbeatThread then
		coroutine.close(self.heartbeatThread)
	end

	self.heartbeatThread = util.coroutineRun(function()
		stdPolyfills.task.wait(milliseconds / 1000)

		self.heartbeatThread = nil

		self:heartbeatAsync()
			:andThen(function()
				return future.Future.new(function()
					self:heartbeatIn(milliseconds)
				end) :: future.FutureLike<string, nil>
			end)
			:after(function(result)
				if result:isErr() then
					self.logger:warn(`heartbeat loop error: {result:unwrapErr()}`)
				end
			end)
			:await()
	end)
end

--[=[
	@within Voice.WebSocketTransport

	Opens the WebSocket to the given URL, starts the receive loop, and fires `onConnected`.
]=]
function WebSocketTransport.Prototype._openSocket(self: WebSocketTransport, url: string)
	local ok, socket = pcall(stdPolyfills.net.tcpSocket, url)
	assert(ok, tostring(socket))

	self.socketInstance = socket
	self.socketActive = true

	self.logger:info(`voice WebSocket connected, starting receive loop`)

	self.socketThread = util.coroutineRun(function()
		local myThread = coroutine.running()

		if self.onConnected then
			self.onConnected()
		end

		while self.socketActive and self.socketInstance and self.socketThread == myThread do
			assert(self.socketInstance, `Voice socket instance is nil.`)

			if self.socketInstance.closeCode then
				self.logger:warn(`voice socket closed by server: {self.socketInstance.closeCode}`)
				self.socketActive = false
			else
				local success, response = pcall(self.socketInstance.next)

				if not self.socketActive then
					continue
				elseif not self.socketInstance then
					self.logger:warn(`voice socket missing: {response and response or "no error"}`)
					self.socketActive = false
				elseif success and response then
					self:_handleMessage(response :: string)
				else
					self.logger:warn(`voice socket receive error: {response and response or "no error"}`)
					self.socketActive = false
				end
			end
		end

		if self.socketThread ~= myThread then
			return
		end

		local sock = self.socketInstance
		self.socketThread = nil
		self.socketInstance = nil

		self.logger:info(`voice receive loop stopped`)

		if self.socketReconnecting then
			return
		end

		if self.onDisconnected then
			if sock then
				self.onDisconnected(sock.closeCode, nil)
			elseif self.socketDisconnecting then
				self.onDisconnected(-1, true)
			else
				self.onDisconnected(-1, nil)
			end
		end
	end)
end

--[=[
	@within Voice.WebSocketTransport

	Synchronously closes the voice WebSocket and kills all associated threads. Safe to call from
	a signal handler or any context where yielding is not permitted.
]=]
function WebSocketTransport.Prototype.forceClose(self: WebSocketTransport, code: number?)
	if self.heartbeatThread then
		coroutine.close(self.heartbeatThread)
		self.heartbeatThread = nil
	end

	if self.socketThread then
		if coroutine.status(self.socketThread) == "suspended" then
			coroutine.close(self.socketThread)
		end
		self.socketThread = nil
	end

	if self.socketInstance and not self.socketInstance.closeCode then
		xpcall(function()
			self.socketInstance.close(code)
		end, function(err)
			self.logger:info(`error during voice socket close, assuming closed: {tostring(err)}`)
		end)
	end

	self.socketInstance = nil
	self.socketActive = false

	self.logger:info(`voice WebSocket closed`)
end

--[=[
	@within Voice.WebSocketTransport

	Responsible for constructing this class.
]=]
function WebSocketTransport.Interface.new(loggerInstance: logger.Logger): WebSocketTransport
	return setmetatable(
		{
			socketActive = false,
			socketReconnecting = false,
			socketDisconnecting = false,
			isResuming = false,
			heartbeatAcknowledged = true,
			sequenceAcknowledgement = 0,
			logger = loggerInstance,
		} :: WebSocketTransport,
		{ __index = WebSocketTransport.Prototype }
	)
end

export type WebSocketTransport = typeof(WebSocketTransport.Prototype) & {
	socketActive: boolean,
	socketReconnecting: boolean,
	socketDisconnecting: boolean,
	isResuming: boolean,
	socketInstance: any?,
	socketThread: thread?,
	heartbeatInterval: number?,
	heartbeatThread: thread?,
	heartbeatAcknowledged: boolean,
	heartbeatClockTime: number?,
	heartbeatPing: number?,
	sequenceAcknowledgement: number,
	onConnected: (() -> ())?,
	onDisconnected: ((code: number?, closedBySelf: boolean?) -> ())?,
	onMessage: ((payload: any) -> ())?,
	onZombified: (() -> ())?,
	logger: logger.Logger,
}

return WebSocketTransport.Interface
