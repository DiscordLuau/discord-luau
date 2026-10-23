local stdPolyfills = require("../luau_packages/std_polyfills")
local future = require("../luau_packages/future")
local logger = require("../luau_packages/logger")
local apiTypes = require("../luau_packages/api_types")

local NORMAL_CLOSE_CODE = 1000
local JSON_OPENING_BRACE = string.byte("{")

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
	@prop socketDisconnecting boolean
	@within Voice.WebSocketTransport
]=]

--[=[
	@prop socketOpening boolean
	@within Voice.WebSocketTransport
]=]

--[=[
	@prop openAttempt number
	@within Voice.WebSocketTransport

	Counts opens and `forceClose` calls; an open that finishes under an older count was abandoned and leaves
	`socketOpening` alone.
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

	Decodes an incoming voice gateway message and dispatches it to `onMessage`. A binary frame is unwrapped from the
	voice binary framing (a 2-byte sequence number, then the opcode); a text frame is decoded as JSON. When the socket
	cannot say which kind of frame it was (`isBinary` is nil), a message whose first byte is not `{` is treated as
	binary.
]=]
function WebSocketTransport.Prototype.handleMessage(self: WebSocketTransport, message: string, isBinary: boolean?)
	local binary = if isBinary == nil then string.byte(message, 1) ~= JSON_OPENING_BRACE else isBinary

	if binary then
		local messageBuffer = buffer.fromstring(message)

		if buffer.len(messageBuffer) < 3 then
			self.logger:warn(`ignoring a binary voice message of {buffer.len(messageBuffer)} bytes, too short to frame`)

			return
		end

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
			self.logger:warn(`failed to decode voice WebSocket message: {payload}`)

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

		local sent = self:sendAsync(stdPolyfills.serde.encode("json" :: any, {
			op = apiTypes.voice.opcodes.Heartbeat,
			d = {
				t = math.floor(os.clock() * 1000),
				seq_ack = self.sequenceAcknowledgement,
			},
		}, true)):await()

		assert(sent:isOk(), `heartbeat send failed: {sent:unwrapErr()}`)
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Voice.WebSocketTransport

	Schedules the next heartbeat to fire after the given number of milliseconds, cancelling any pending heartbeat.
]=]
function WebSocketTransport.Prototype.heartbeatIn(self: WebSocketTransport, milliseconds: number)
	local thread = coroutine.create(function()
		stdPolyfills.task.wait(milliseconds / 1000)

		self.heartbeatThread = nil

		if not self.socketActive then
			self.logger:debug(`not sending a voice heartbeat: the socket is down`)

			return
		end

		local beat = self:heartbeatAsync():await()

		if beat:isErr() then
			self.logger:warn(`heartbeat loop error: {beat:unwrapErr()}`)
		end

		self:heartbeatIn(milliseconds)
	end)

	self:stopHeartbeat()

	self.heartbeatThread = thread

	self:resumeThread(thread, "heartbeat")
end

--[=[
	@within Voice.WebSocketTransport

	Cancels the pending heartbeat, if any.
]=]
function WebSocketTransport.Prototype.stopHeartbeat(self: WebSocketTransport)
	local thread = self.heartbeatThread

	self.heartbeatThread = nil

	self:closeThread(thread, "heartbeat")
end

--[=[
	@within Voice.WebSocketTransport
	@private

	Resumes a thread this transport owns, logging at warn with a traceback if it errors before its first yield.
]=]
function WebSocketTransport.Prototype.resumeThread(self: WebSocketTransport, thread: thread, purpose: string)
	local resumed, resumeError = coroutine.resume(thread)

	if not resumed then
		self.logger:warn(`voice {purpose} thread errored:\n{debug.traceback(thread, tostring(resumeError))}`)
	end
end

--[=[
	@within Voice.WebSocketTransport
	@private

	Closes a thread this transport owns when it is suspended. A running or resuming thread cannot be closed;
	its loop checks the transport's state and stops on its own.
]=]
function WebSocketTransport.Prototype.closeThread(self: WebSocketTransport, thread: thread?, purpose: string)
	if not thread or coroutine.status(thread) ~= "suspended" then
		self.logger:debug(
			`not closing the {purpose} thread: {if thread then coroutine.status(thread) else "there is none"}`
		)

		return
	end

	local closed, closeError = coroutine.close(thread)

	if not closed then
		self.logger:warn(`voice {purpose} thread errored while closing: {closeError}`)
	end
end

--[=[
	@within Voice.WebSocketTransport

	Opens the WebSocket to the given URL, starts the receive loop, and fires `onConnected`. Raises when a socket is
	already open or opening. When `isStillWanted` returns false once the handshake finishes, or `forceClose` abandoned
	the open during it, the new socket is closed at once and nothing starts.
]=]
function WebSocketTransport.Prototype.openSocket(self: WebSocketTransport, url: string, isStillWanted: (() -> boolean)?)
	local openAttempt = self.openAttempt + 1

	assert(not self.socketActive and not self.socketOpening, `voice WebSocket is already open or opening`)

	self.openAttempt = openAttempt
	self.socketOpening = true

	local opened, socket = pcall(stdPolyfills.net.tcpSocket, url)
	local abandoned = self.openAttempt ~= openAttempt

	if not abandoned then
		self.socketOpening = false
	end

	assert(opened, tostring(socket))

	if abandoned or (isStillWanted and not isStillWanted()) then
		local closed, closeError = pcall((socket :: any).close, NORMAL_CLOSE_CODE)

		if not closed then
			self.logger:debug(`closing an unwanted voice WebSocket errored: {closeError}`)
		end

		self.logger:debug(`closed a voice WebSocket that finished opening after it stopped being wanted`)

		return
	end

	local thread = coroutine.create(function()
		local myThread = coroutine.running()

		if self.onConnected then
			self.onConnected()
		end

		while self.socketActive and self.socketInstance and self.socketThread == myThread do
			assert(self.socketInstance, `Voice socket instance is nil.`)

			if self.socketInstance.closeCode then
				self.logger:info(`voice socket closed by server: {self.socketInstance.closeCode}`)
				self.socketActive = false
			else
				local success, response, isBinary = pcall(self.socketInstance.nextMessage or self.socketInstance.next)

				if not self.socketActive then
					self.logger:debug(`voice socket was closed while waiting for a message`)

					continue
				elseif not self.socketInstance then
					self.logger:warn(`voice socket missing: {response or "no error"}`)
					self.socketActive = false
				elseif success and response then
					local handled, handleError = xpcall(
						self.handleMessage :: (...any) -> ...any,
						debug.traceback,
						self,
						response :: string,
						isBinary
					)

					if not handled then
						self.logger:warn(`voice WebSocket message handler errored:\n{handleError}`)
					end
				elseif success then
					self.logger:info(`voice socket closed: {self.socketInstance.closeCode or "no close code"}`)
					self.socketActive = false
				else
					self.logger:warn(`voice socket receive error: {response}`)
					self.socketActive = false
				end
			end
		end

		if self.socketThread ~= myThread then
			self.logger:debug(`a newer voice receive loop replaced this one, stopping without cleanup`)

			return
		end

		local sock = self.socketInstance
		self.socketThread = nil
		self.socketInstance = nil

		self.logger:info(`voice receive loop stopped`)

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

	self.socketInstance = socket
	self.socketActive = true
	self.socketThread = thread

	self.logger:info(`voice WebSocket connected, starting receive loop`)

	self:resumeThread(thread, "receive loop")
end

--[=[
	@within Voice.WebSocketTransport

	Synchronously closes the voice WebSocket and kills all associated threads. Safe to call from
	a signal handler or any context where yielding is not permitted. An open still in its handshake is abandoned: it
	closes its socket when the handshake finishes, and a new open may start at once.
]=]
function WebSocketTransport.Prototype.forceClose(self: WebSocketTransport, code: number?)
	local socketThread = self.socketThread

	self.socketThread = nil
	self.openAttempt += 1
	self.socketOpening = false

	self:stopHeartbeat()
	self:closeThread(socketThread, "receive loop")

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
			socketDisconnecting = false,
			openAttempt = 0,
			isResuming = false,
			heartbeatAcknowledged = true,
			sequenceAcknowledgement = -1,
			logger = loggerInstance,
		} :: WebSocketTransport,
		{ __index = WebSocketTransport.Prototype }
	)
end

export type WebSocketTransport = typeof(WebSocketTransport.Prototype) & {
	socketActive: boolean,
	socketDisconnecting: boolean,
	socketOpening: boolean,
	openAttempt: number,
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
