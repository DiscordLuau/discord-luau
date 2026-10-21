local stdPolyfills = require("../luau_packages/std_polyfills")

local accumulator = require("../luau_packages/accumulator")
local emitter = require("../luau_packages/emitter")
local future = require("../luau_packages/future")
local logger = require("../luau_packages/logger")
local secret = require("../luau_packages/secret")

local util = require("../luau_packages/util")
local apiTypes = require("../luau_packages/api_types")

local GATEWAY_SEND_LIMIT = 120
local GATEWAY_SEND_WINDOW_SECONDS = 60
local GATEWAY_SEND_SAFE_LIMIT = GATEWAY_SEND_LIMIT - 2
local GATEWAY_SEND_WARN_AFTER_SECONDS = 5

local LIBRARY_IDENTIFIER = "DiscordLuau"

local RECONNECT_BACKOFF_INITIAL_SECONDS = 1
local RECONNECT_BACKOFF_MAX_SECONDS = 30
local IDENTIFY_MIN_INTERVAL_SECONDS = 90
local SESSION_OUTCOME_TIMEOUT_SECONDS = 30
local STOP_POLL_SECONDS = 0.25
local RECONNECT_CLOSE_CODE = 1012
local SESSION_END_CLOSE_CODE = 1000

local FATAL_CLOSE_CODES: { [number]: string } = table.freeze({
	[apiTypes.gateway.closeCodes.AuthenticationFailed] = "failed to authenticate with the Discord API, is your token correct?",
	[apiTypes.gateway.closeCodes.InvalidShard] = "invalid shard, please create an issue on the Discord-Luau repository",
	[apiTypes.gateway.closeCodes.ShardingRequired] = "too many guilds for a single shard - increase your shard count and restart",
	[apiTypes.gateway.closeCodes.InvalidAPIVersion] = "invalid gateway API version, please create an issue on the Discord-Luau repository",
	[apiTypes.gateway.closeCodes.InvalidIntents] = "invalid intents, please create an issue on the Discord-Luau repository",
	[apiTypes.gateway.closeCodes.DisallowedIntents] = "disallowed intents, are the chosen intents enabled for this bot?",
})

local FRESH_SESSION_CLOSE_CODES: { [number]: boolean } = table.freeze({
	[apiTypes.gateway.closeCodes.NotAuthenticated] = true,
	[apiTypes.gateway.closeCodes.InvalidSeq] = true,
	[apiTypes.gateway.closeCodes.SessionTimedOut] = true,
})

--[=[
	@class WebSocket.Shard
	@__index Prototype

	Shard is responsible for managing a single WebSocket connection to Discord's Gateway API.
	Its key responsibilities include:

	1. Establishing and maintaining a WebSocket connection
	2. Handling incoming messages:
		- Decompressing ZLIB-compressed messages
		- Decoding JSON payloads
		- Invoking callbacks for processed messages
	3. Sending outgoing messages, including heartbeats
	4. Managing the heartbeat mechanism:
		- Sending periodic heartbeats to keep the connection alive
		- Tracking heartbeat acknowledgements
		- Initiating reconnection if heartbeats are not acknowledged
	5. Reconnecting through one reconnect loop that resumes the session when it can, identifies when it cannot,
		backs off between attempts, and only reconnects on its own when `shouldReconnect` is set
	6. Providing an interface for other parts of the application to interact with the WebSocket connection

	The Shard module is crucial for maintaining real-time communication with Discord's Gateway,
	ensuring the bot stays connected and can send and receive updates efficiently.
]=]

--[=[
	@prop token Secret 
	@within WebSocket.Shard
]=]

--[=[
	@prop intents number
	@within WebSocket.Shard
]=]

--[=[
	@prop shardId number
	@within WebSocket.Shard
]=]

--[=[
	@prop shardCount number
	@within WebSocket.Shard
]=]

--[=[
	@prop shouldReconnect boolean
	@within WebSocket.Shard
]=]

--[=[
	@prop largeThreshold number?
	@within WebSocket.Shard
]=]

--[=[
	@prop zlibBuffer Accumulator
	@within WebSocket.Shard
]=]

--[=[
	@prop onSocketConnected Emitter<()>
	@within WebSocket.Shard
]=]

--[=[
	@prop onSocketReconnected Emitter<number?>
	@within WebSocket.Shard
]=]

--[=[
	@prop onSocketDisconnected Emitter<number?, boolean?>
	@within WebSocket.Shard
]=]

--[=[
	@prop onSocketHeartbeat Emitter<number?>
	@within WebSocket.Shard
]=]

--[=[
	@prop onSocketDispatch Emitter<apiTypes.Payload<unknown>>
	@within WebSocket.Shard
]=]

--[=[
	@prop onSocketRawMessage Emitter<apiTypes.Payload<unknown>>
	@within WebSocket.Shard
]=]

--[=[
	@prop onSocketReady Emitter<()>
	@within WebSocket.Shard
]=]

--[=[
	@prop onSocketRateLimited Emitter<{ opcode: number, retryAfter: number, guildId: string? }>
	@within WebSocket.Shard
]=]

--[=[
	@prop heartbeatAcknowledged boolean?
	@within WebSocket.Shard
]=]

--[=[
	@prop heartbeatClockTime number?
	@within WebSocket.Shard
]=]

--[=[
	@prop heartbeatInterval number?
	@within WebSocket.Shard
]=]

--[=[
	@prop heartbeatThread thread?
	@within WebSocket.Shard
]=]

--[=[
	@prop heartbeatPing number?
	@within WebSocket.Shard
]=]

--[=[
	@prop lastSequence number?
	@within WebSocket.Shard
]=]

--[=[
	@prop logger Logger
	@within WebSocket.Shard
]=]

--[=[
	@prop socketActive boolean
	@within WebSocket.Shard
]=]

--[=[
	@prop socketReconnecting boolean
	@within WebSocket.Shard
]=]

--[=[
	@prop socketDisconnecting boolean
	@within WebSocket.Shard
]=]

--[=[
	@prop socketIdentified boolean
	@within WebSocket.Shard
]=]

--[=[
	@prop sessionId string?
	@within WebSocket.Shard
]=]

--[=[
	@prop sessionGateway string?
	@within WebSocket.Shard
]=]

--[=[
	@prop socketVersion number?
	@within WebSocket.Shard
]=]

--[=[
	@prop socketUrl string?
	@within WebSocket.Shard
]=]

--[=[
	@prop socketInstance any?
	@within WebSocket.Shard
]=]

--[=[
	@prop socketThread thread?
	@within WebSocket.Shard
]=]

--[=[
	@prop gatewaySendTimestamps { number }
	@within WebSocket.Shard

	Rolling log of `os.clock()` timestamps for every non-heartbeat send, used to enforce Discord's 120-events-per-60s gateway send rate limit.
]=]

--[=[
	@prop stayDisconnected boolean
	@within WebSocket.Shard

	`true` while the shard stays down until an explicit `connectAsync` or `reconnectAsync`: after `disconnectAsync` or `forceClose`, a failed `connectAsync`, a fatal close code, a reconnect loop that threw, or an automatic reconnect while `shouldReconnect` is off.
]=]

--[=[
	@prop sessionOutcome SessionOutcome?
	@within WebSocket.Shard

	What the gateway answered on the current socket (READY, RESUMED, op 7 or op 9); read by the reconnect loop.
]=]

--[=[
	@prop closeCode number?
	@within WebSocket.Shard

	Close code the server sent when it last closed the shard's socket.
]=]

--[=[
	@prop lastIdentifyTimestamp number?
	@within WebSocket.Shard

	Unix time in seconds of the last IDENTIFY, used to keep reconnects under Discord's daily IDENTIFY limit.
]=]

--[=[
	@prop socketGeneration number
	@within WebSocket.Shard

	Counts sockets opened; an automatic reconnect raised by a socket that has since been replaced is dropped.
]=]

local Shard = {}

Shard.Interface = {}
Shard.Prototype = {}

--[=[
	@within WebSocket.Shard
	@private

	Forgets the session id, resume gateway and last sequence so the next connection identifies instead of resuming.
]=]
function Shard.Prototype._dropSession(self: Shard)
	self.sessionId = nil
	self.sessionGateway = nil
	self.lastSequence = nil
end

--[=[
	@within WebSocket.Shard
	@private

	Logs why the close code is fatal, marks the shard to stay disconnected and forgets its session.
]=]
function Shard.Prototype._stayDownOnFatalClose(self: Shard, closeCode: number?, fatalReason: string)
	self.logger:warn(`Shard '{self.shardId}' closed with code {closeCode}: {fatalReason} - staying disconnected`)
	self.stayDisconnected = true

	self:_dropSession()
end

--[=[
	@within WebSocket.Shard
	@private

	Returns true while the given socket is still the open socket of a shard not told to stay disconnected.
]=]
function Shard.Prototype._isCurrentSocket(self: Shard, socket: any): boolean
	return self.socketInstance == socket and self.socketActive and not self.stayDisconnected
end

--[=[
	@within WebSocket.Shard
	@private

	Cancels the heartbeat thread, clears the socket fields and sends `code` unless the server already closed the socket.
]=]
function Shard.Prototype._closeSocket(self: Shard, code: number?)
	local socket = self.socketInstance
	local heartbeatThread = self.heartbeatThread

	if heartbeatThread and coroutine.status(heartbeatThread) == "suspended" then
		stdPolyfills.task.cancel(heartbeatThread)
	end

	self.heartbeatThread = nil
	self.socketThread = nil
	self.socketInstance = nil
	self.socketActive = false
	self.socketIdentified = false

	if socket and not socket.closeCode then
		local closed, closeError = pcall(socket.close, code)

		if not closed then
			self.logger:info(
				`Error during socketInstance.close, assuming socket has been closed: {tostring(closeError)}`
			)
		end
	end
end

--[=[
	@within WebSocket.Shard
	@private

	Yields for `seconds` in short polls, returning false as soon as the shard is told to stay disconnected.
]=]
function Shard.Prototype._waitUnlessStopped(self: Shard, seconds: number): boolean
	local waited = 0

	while waited < seconds do
		if self.stayDisconnected then
			return false
		end

		waited += stdPolyfills.task.wait(math.min(STOP_POLL_SECONDS, seconds - waited))
	end

	return not self.stayDisconnected
end

--[=[
	@within WebSocket.Shard
	@private

	Polls until the gateway answers, the socket closes, the shard stops or the timeout passes, and returns which one.
]=]
function Shard.Prototype._awaitSessionOutcome(self: Shard): LoopOutcome
	local waited = 0

	while
		not self.stayDisconnected
		and self.socketActive
		and not self.sessionOutcome
		and waited < SESSION_OUTCOME_TIMEOUT_SECONDS
	do
		waited += stdPolyfills.task.wait(STOP_POLL_SECONDS)
	end

	if self.stayDisconnected then
		return "Stopped"
	elseif not self.socketActive then
		return "Closed"
	elseif self.sessionOutcome then
		return self.sessionOutcome
	end

	return "TimedOut"
end

--[=[
	@within WebSocket.Shard
	@private

	Defers a reconnect loop when the raising socket is still current, or, with `shouldReconnect` off, keeps the shard
	down and closes its socket.
]=]
function Shard.Prototype._reconnectAutomatically(self: Shard, reason: string, generation: number)
	if generation ~= self.socketGeneration or self.stayDisconnected then
		return
	end

	if not self.shouldReconnect then
		local socketWasActive = self.socketActive

		self.logger:notice(`reconnect disabled, staying disconnected ({reason})`)
		self.stayDisconnected = true

		self:_dropSession()

		if socketWasActive then
			self:_closeSocket(SESSION_END_CLOSE_CODE)
			self.onSocketDisconnected:invoke(-1)
		end

		return
	end

	stdPolyfills.task.defer(function()
		if generation ~= self.socketGeneration or self.stayDisconnected then
			return
		end

		self:_startReconnectLoop():poll()
	end)
end

--[=[
	@within WebSocket.Shard
	@private

	Unless a reconnect loop is running, stays down on a fatal code, forgets the session on a fresh-session code and
	reconnects otherwise.
]=]
function Shard.Prototype._handleServerClose(self: Shard, closeCode: number?, generation: number)
	local fatalReason = if closeCode then FATAL_CLOSE_CODES[closeCode] else nil

	if self.socketReconnecting then
		return
	end

	if fatalReason then
		self:_stayDownOnFatalClose(closeCode, fatalReason)

		return
	end

	if closeCode and FRESH_SESSION_CLOSE_CODES[closeCode] then
		self:_dropSession()
	end

	self:_reconnectAutomatically(`close code {closeCode or "none"}`, generation)
end

--[=[
	@within WebSocket.Shard
	@private

	Feeds each socket message to `_handleMessage` until the socket ends, then clears the socket fields and acts on the
	close code.
]=]
function Shard.Prototype._receiveUntilClosed(self: Shard, socket: any, generation: number)
	local receiveThread = coroutine.running()

	self.logger:info(`Receive thread started, awaiting messages.`)
	self.onSocketConnected:invoke()

	while true do
		local received, message = pcall(socket.next)

		if self.socketThread ~= receiveThread then
			return
		end

		if not received then
			self.logger:warn(`error during receive: {message}`)

			break
		end

		if not message then
			break
		end

		self:_handleMessage(message)
	end

	local closeCode = socket.closeCode

	self.closeCode = closeCode
	self.socketThread = nil
	self.socketInstance = nil
	self.socketActive = false
	self.socketIdentified = false

	self.logger:info(`socket has disconnected with code {closeCode or "none"}, receive thread stopped.`)

	self:_handleServerClose(closeCode, generation)

	self.onSocketDisconnected:invoke(closeCode)
end

--[=[
	@within WebSocket.Shard
	@private

	Connects a gateway socket under a new generation and starts its receive thread, or returns false and the reason.
]=]
function Shard.Prototype._openSocket(self: Shard, socketUrl: string, socketVersion: number): (boolean, string?)
	if self.socketActive then
		return false, `Shard '{self.shardId}' already connected to a socket.`
	end

	self.socketGeneration += 1
	self.socketIdentified = false
	self.heartbeatAcknowledged = nil
	self.sessionOutcome = nil
	self.closeCode = nil

	local generation = self.socketGeneration

	self.logger:info(`connecting to: {socketUrl}/?v={socketVersion}`)

	local connected, response = pcall(stdPolyfills.net.tcpSocket, `{socketUrl}/?v={socketVersion}`)

	if not connected then
		return false, tostring(response)
	end

	local socket = response

	if not self.socketVersion then
		self.socketVersion = socketVersion
	end

	if not self.socketUrl then
		self.socketUrl = socketUrl
	end

	self.socketInstance = socket
	self.socketActive = true

	self.logger:info(`has connected to: {socketUrl}, starting receive thread.`)

	local thread = coroutine.create(self._receiveUntilClosed)

	self.socketThread = thread

	local started, startError = coroutine.resume(thread, self, socket, generation)

	if not started then
		self.logger:warn(`receive thread failed to start: {startError}`)

		self:_closeSocket(RECONNECT_CLOSE_CODE)

		return false, tostring(startError)
	end

	return true
end

--[=[
	@within WebSocket.Shard
	@private

	Closes the old socket, paces a fresh IDENTIFY, opens a new socket and maps the gateway's answer to a result.
]=]
function Shard.Prototype._runReconnectPass(self: Shard): PassResult
	self:_closeSocket(RECONNECT_CLOSE_CODE)

	if self.stayDisconnected then
		return "Stopped"
	end

	if not self.sessionId and self.lastIdentifyTimestamp then
		local nowSeconds = stdPolyfills.datetime.now().unixTimestampMillis / 1000
		local pacingSeconds = IDENTIFY_MIN_INTERVAL_SECONDS - (nowSeconds - self.lastIdentifyTimestamp)

		if pacingSeconds > 0 and not self:_waitUnlessStopped(pacingSeconds) then
			return "Stopped"
		end
	end

	local socketUrl = if self.sessionId then self.sessionGateway else self.socketUrl
	local opened, openError = self:_openSocket(socketUrl :: string, self.socketVersion :: number)

	if not opened then
		self.logger:warn(`reconnect pass could not open a socket: {openError}`)

		return "Failed"
	end

	if self.stayDisconnected then
		self:_closeSocket(RECONNECT_CLOSE_CODE)

		return "Stopped"
	end

	local outcome = self:_awaitSessionOutcome()
	local closeCode = self.closeCode
	local fatalReason = if closeCode then FATAL_CLOSE_CODES[closeCode] else nil

	if outcome == "Ready" or outcome == "Resumed" then
		return "Succeeded"
	end

	if outcome == "Stopped" then
		self:_closeSocket(RECONNECT_CLOSE_CODE)

		return "Stopped"
	end

	if outcome == "Closed" and fatalReason then
		self:_stayDownOnFatalClose(closeCode, fatalReason)
		self:_closeSocket(RECONNECT_CLOSE_CODE)

		return "Stopped"
	end

	if outcome == "Closed" and closeCode and FRESH_SESSION_CLOSE_CODES[closeCode] then
		self:_dropSession()
	end

	self.logger:warn(`reconnect pass ended without a session: {outcome}`)

	return "Failed"
end

--[=[
	@within WebSocket.Shard
	@private

	Repeats `_runReconnectPass` with doubling backoff until a pass succeeds or stops, retrying one that throws.
]=]
function Shard.Prototype._runReconnectLoop(self: Shard)
	local backoffSeconds = RECONNECT_BACKOFF_INITIAL_SECONDS
	local passCount = 0

	while true do
		local passed, passResult = pcall(self._runReconnectPass, self)

		passCount += 1

		if not passed then
			self.logger:warn(`reconnect pass {passCount} threw: {passResult}`)
		elseif passResult == "Succeeded" then
			self.logger:notice(`reconnection successful after {passCount} pass(es)`)
			self.onSocketReconnected:invoke()

			return
		elseif passResult == "Stopped" then
			return
		end

		self:_closeSocket(RECONNECT_CLOSE_CODE)

		if not self:_waitUnlessStopped(backoffSeconds) then
			return
		end

		backoffSeconds = math.min(backoffSeconds * 2, RECONNECT_BACKOFF_MAX_SECONDS)
	end
end

--[=[
	@within WebSocket.Shard
	@private

	Marks the shard as reconnecting and runs the loop in a future, deferring to a loop already running and keeping the
	shard down if it throws.
]=]
function Shard.Prototype._startReconnectLoop(self: Shard): future.FutureLike<string, nil>
	return future.Future.new(function()
		if self.socketReconnecting then
			self.logger:notice(`Shard is already trying to reconnect, leaving it to the running reconnect`)

			return
		end

		self.socketReconnecting = true

		self.logger:notice(`reconnection requested, reconnecting..`)

		local finished, loopError = pcall(self._runReconnectLoop :: (Shard) -> ...unknown, self)

		self.socketReconnecting = false

		if finished then
			return
		end

		self.logger:warn(`reconnect loop threw, staying disconnected: {loopError}`)
		self.stayDisconnected = true

		self:_closeSocket(RECONNECT_CLOSE_CODE)
		self.onSocketDisconnected:invoke(-1)
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within WebSocket.Shard
	@private

	Function responsible for handling incoming messages from the WebSocket connection.
	
	It performs the following steps:
	1. Decompresses the incoming message if it's ZLIB-compressed
		i. It's worth noting that payloads may not be complete, meaning we should add data to the
			buffer until we have a complete message
	2. Decodes the JSON payload
	3. Invokes the appropriate callback based on the received event type

	Roughly based on the following documentation:
	https://discord.com/developers/docs/topics/gateway#zlibstream
]=]
function Shard.Prototype._handleMessage(self: Shard, message: string): ()
	local isJson, jsonContent = pcall(stdPolyfills.serde.decode, "json" :: any, message)

	if isJson then
		self.logger:debug(`received message: #{string.len(message)}`)

		self.onSocketRawMessage:invoke(jsonContent)
	else
		self.zlibBuffer:write(message)

		local success0, response0 = pcall(stdPolyfills.serde.decompress, "zlib" :: any, self.zlibBuffer:peek())

		if success0 then
			self.logger:debug(`decompressed Shard message: #{string.len(response0)}`)
			self.zlibBuffer:flush()

			local success1, response1 = pcall(stdPolyfills.serde.decode, "json" :: any, response0)

			if success1 then
				self.onSocketRawMessage:invoke(response1)
			else
				self.logger:warn(`failed to decode Shard JSON message: {response1}`)
			end
		else
			self.logger:debug(`received complete message: #{string.len(message)}, decompressing...`)
		end
	end
end

--[=[
	@within WebSocket.Shard

	Sends a heartbeat to the Discord Gateway API. When the previous heartbeat was never acknowledged and no
	reconnect is running, the socket is treated as zombified: an automatic reconnect is raised instead.
]=]
function Shard.Prototype.heartbeatAsync(self: Shard, requested: boolean?)
	return future.Future.new(function()
		if not self.heartbeatAcknowledged and not requested and not self.socketReconnecting then
			self.logger:info(`discord WebSocket state has become Zombified, reconnecting...`)

			self:_reconnectAutomatically("zombie heartbeat", self.socketGeneration)

			return
		end

		self.heartbeatClockTime = os.clock()
		self.heartbeatAcknowledged = false

		self.logger:info(`sending heartbeat request`)

		self:sendAsync(
			stdPolyfills.serde.encode("json", {
				["op"] = apiTypes.gateway.opcodes.Heartbeat,
				["d"] = self.lastSequence or false,
			}, true),
			true
		)
			:after(function(result)
				if result:isErr() then
					self.logger:warn(`shard has run into an error during heartbeat send: {result:unwrapErr()}`)
				end
			end)
			:await()
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within WebSocket.Shard

	Identifies the current shard with the Discord Gateway, and records when it did so the reconnect loop can pace
	the next IDENTIFY.
]=]
function Shard.Prototype.identifyAsync(self: Shard)
	return future.Future.new(function()
		self.logger:info(`sending identify request`)
		self.lastIdentifyTimestamp = stdPolyfills.datetime.now().unixTimestampMillis / 1000

		self:sendAsync(stdPolyfills.serde.encode("json", {
			["op"] = apiTypes.gateway.opcodes.Identify,
			["d"] = {
				["token"] = self.token.value,
				["intents"] = self.intents,
				["compress"] = stdPolyfills.runtime.capabilities().compress,
				["large_threshold"] = self.largeThreshold or 250,
				["shard"] = {
					self.shardId,
					self.shardCount,
				},
				["properties"] = {
					["os"] = stdPolyfills.process.getPlatform(),
					["browser"] = LIBRARY_IDENTIFIER,
					["device"] = LIBRARY_IDENTIFIER,
				},
			},
		}, true))
			:after(function(result)
				if result:isErr() then
					self.logger:warn(`shard has run into an error during identify send: {result:unwrapErr()}`)
				end
			end)
			:await()
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within WebSocket.Shard

	Sends op 6 Resume for the current session, carrying the last sequence seen so Discord replays what was missed.
]=]
function Shard.Prototype.sendResumeAsync(self: Shard)
	return future.Future.new(function()
		self.logger:notice(`attempting to resume..`)

		local result = self:sendAsync(stdPolyfills.serde.encode("json", {
			["op"] = apiTypes.gateway.opcodes.Resume,
			["d"] = {
				["token"] = self.token.value,
				["session_id"] = self.sessionId,
				["seq"] = self.lastSequence,
			},
		}, true)):await()

		if result:isErr() then
			self.logger:warn(`shard has run into an error during resume send: {result:unwrapErr()}`)
		end
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within WebSocket.Shard

	Synchronously closes the shard's socket, ends its session and stops its threads, and keeps the shard down until
	`connectAsync` or `reconnectAsync` is called. Safe to call from a signal handler or any context where yielding is
	not permitted.
]=]
function Shard.Prototype.forceClose(self: Shard, code: number?)
	self.logger:info(`force closing shard {self.shardId}`)
	self.stayDisconnected = true

	self:_dropSession()
	self:_closeSocket(code)

	self.logger:info(`shard {self.shardId} closed`)
end

--[=[
	@within WebSocket.Shard

	Disconnects the Shard from the Discord Gateway and keeps it down until `connectAsync` or `reconnectAsync` is
	called.

	Optionally, a WebSocket close code can be provided, websocket close code spec can be found here:
	https://developer.mozilla.org/en-US/docs/Web/API/CloseEvent/code
]=]
function Shard.Prototype.disconnectAsync(self: Shard, code: number?)
	return future.Future.new(function()
		self.logger:info(`requesting disconnect: {code or 0}`)
		self.socketDisconnecting = true
		self:forceClose(code)
		self.onSocketDisconnected:invoke(-1, true)
		self.socketDisconnecting = false
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within WebSocket.Shard

	Connects the shard to a Discord Gateway with a fresh session; the first heartbeat acknowledgement identifies.

	Expects both a Socket URL, and Socket Version to be provided. It will prepend the socket version
	to the socket URL, and then connect to the socket.

	Resolves Err when the shard already has an open socket or the connection fails; a failed connection leaves the
	shard down. While a reconnect is running, it leaves the connection to that reconnect.
]=]
function Shard.Prototype.connectAsync(self: Shard, socketUrl: string, socketVersion: number)
	return future.Future.new(function()
		assert(not self.socketActive, `Shard '{self.shardId}' already connected to a socket.`)

		self.stayDisconnected = false

		if self.socketReconnecting then
			self.logger:notice(`Shard is already trying to reconnect, leaving the connection to it`)

			return
		end

		self:_dropSession()

		local opened, openError = self:_openSocket(socketUrl, socketVersion)

		if not opened then
			self.stayDisconnected = true
		end

		assert(opened, openError)
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within WebSocket.Shard

	Reconnects the shard and resumes its session; the reconnect loop identifies instead when no session is left.
]=]
function Shard.Prototype.resumeAsync(self: Shard)
	return self:reconnectAsync()
end

--[=[
	@within WebSocket.Shard

	Closes the WebSocket connection and reconnects the shard, resuming the session when one exists. Retries with
	backoff until it succeeds, a fatal close code arrives, or the shard is closed. An explicit call always
	reconnects, whatever `shouldReconnect` says.
]=]
function Shard.Prototype.reconnectAsync(self: Shard)
	self.stayDisconnected = false

	return self:_startReconnectLoop()
end

--[=[
	@within WebSocket.Shard

	Sends a message through the WebSocket to Discords Gateway.

	NOTE: Messages are expected to be JSON encoded strings.

	Pass `ignoreRateLimit = true` to bypass the 120-events-per-60s send rate limit tracking.
	This should only be used for op 1 (Heartbeat) sends, which Discord explicitly exempts.
]=]
function Shard.Prototype.sendAsync(self: Shard, data: string, ignoreRateLimit: boolean?)
	local debugTraceback = debug.traceback()

	return future.Future.new(function()
		assert(self.socketActive and self.socketInstance, `Shard '{self.shardId}' not connected to a socket.`)

		if not ignoreRateLimit then
			local timeWaited = 0
			local hasWarned = false

			repeat
				local cutoff = os.clock() - GATEWAY_SEND_WINDOW_SECONDS
				local writeIndex = 1

				for _, timestamp in self.gatewaySendTimestamps do
					if timestamp >= cutoff then
						self.gatewaySendTimestamps[writeIndex] = timestamp
						writeIndex += 1
					end
				end

				for pruneIndex = writeIndex, #self.gatewaySendTimestamps do
					self.gatewaySendTimestamps[pruneIndex] = nil
				end

				if #self.gatewaySendTimestamps >= GATEWAY_SEND_SAFE_LIMIT then
					timeWaited += stdPolyfills.task.wait(0.5)

					if timeWaited > GATEWAY_SEND_WARN_AFTER_SECONDS and not hasWarned then
						hasWarned = true

						self.logger:warn(
							`gateway send rate limit reached ({GATEWAY_SEND_SAFE_LIMIT}/{GATEWAY_SEND_LIMIT} events in {GATEWAY_SEND_WINDOW_SECONDS}s window), yielding until window clears`
						)
					end
				end
			until #self.gatewaySendTimestamps < GATEWAY_SEND_SAFE_LIMIT

			table.insert(self.gatewaySendTimestamps, os.clock())
		end

		self.logger:debug(`sending message of length: {string.len(data)}`)

		local success, response: string? = pcall(self.socketInstance.send, data, true)

		if not success then
			self.socketActive = false

			self.logger:warn(`error during send: {response}\nTraceback: {debugTraceback}`)
		end
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within WebSocket.Shard

	Ends the session and reconnects the shard with a fresh IDENTIFY on the original gateway URL.

	Any events between the disconnection and the new session will not be recovered. If this is
	what you intend to avoid, use `Shard:reconnectAsync` instead.
]=]
function Shard.Prototype.reinstantiateAsync(self: Shard)
	self:_dropSession()

	return self:reconnectAsync()
end

--[=[
	@within WebSocket.Shard

	Sends a heartbeat after `milliseconds` milliseconds, looping and continuing to heartbeat 
	until the socket it started on is closed or replaced, or the shard is told to stay disconnected.
]=]
function Shard.Prototype.heartbeatIn(self: Shard, milliseconds: number): ()
	local previousThread = self.heartbeatThread
	local socket = self.socketInstance

	if previousThread and coroutine.status(previousThread) == "suspended" then
		stdPolyfills.task.cancel(previousThread)
	end

	self.logger:debug(`to heartbeat in '{milliseconds}' ms`)

	self.heartbeatThread = util.coroutineRun(function()
		stdPolyfills.task.wait(milliseconds / 1000)

		if not self:_isCurrentSocket(socket) then
			return
		end

		self:heartbeatAsync():await()

		if not self:_isCurrentSocket(socket) then
			return
		end

		self:heartbeatIn(milliseconds)
	end)
end

--[=[
	@within WebSocket.Shard

	Will instantiate a new Shard class.
]=]
function Shard.Interface.new(settings: {
	token: secret.Secret<string>,

	intents: number,
	shardId: number,
	shardCount: number,
	shouldReconnect: boolean,

	logLevel: logger.LogLevel,

	largeThreshold: number?,
}): Shard
	local self: Shard = setmetatable(
		{
			token = settings.token,
			intents = settings.intents,
			shardId = settings.shardId,
			shardCount = settings.shardCount,
			shouldReconnect = settings.shouldReconnect,

			largeThreshold = settings.largeThreshold,

			zlibBuffer = accumulator.new(),

			onSocketConnected = emitter.new(),
			onSocketReconnected = emitter.new(),
			onSocketDisconnected = emitter.new(),

			onSocketHeartbeat = emitter.new(),

			onSocketDispatch = emitter.new(),
			onSocketRawMessage = emitter.new(),
			onSocketReady = emitter.new(),
			onSocketRateLimited = emitter.new(),

			logger = logger.new(`Shard<{settings.shardId}>`, settings.logLevel),

			socketActive = false,
			socketReconnecting = false,
			socketDisconnecting = false,
			socketIdentified = false,
			stayDisconnected = false,
			socketGeneration = 0,

			rateLimitedGuilds = {} :: { [string]: boolean },
			gatewaySendTimestamps = {} :: { number },
		} :: any,
		{ __index = Shard.Prototype }
	)

	-- The following handles "raw" payload/messages from the Discord Websocket.
	self.onSocketRawMessage:listen(function(payload)
		if payload.op == apiTypes.gateway.opcodes.Dispatch then
			-- https://discord.com/developers/docs/topics/gateway#dispatch-events
			self.logger:debug(`received dispatch message: {payload.t}`)

			self.lastSequence = payload.s

			if payload.t == apiTypes.gateway.receiveEvents.RateLimited then
				local messageObject = payload :: apiTypes.RateLimitedPayload

				self.logger:warn(
					`gateway rate limited on opcode {messageObject.d.opcode}, retry after {messageObject.d.retry_after}s`
				)

				local guildId: string? = nil

				if messageObject.d.opcode == apiTypes.gateway.opcodes.RequestGuildMembers then
					guildId = if messageObject.d.meta then messageObject.d.meta.guild_id else nil

					if guildId then
						local retryAfter = messageObject.d.retry_after

						self.rateLimitedGuilds[guildId] = true

						util.coroutineRun(function()
							stdPolyfills.task.wait(retryAfter)
							self.rateLimitedGuilds[guildId :: string] = nil
						end)
					end
				end

				self.onSocketRateLimited:invoke({
					opcode = messageObject.d.opcode,
					retryAfter = messageObject.d.retry_after,
					guildId = guildId,
				})

				return
			end

			self.onSocketDispatch:invoke(payload)
		elseif payload.op == apiTypes.gateway.opcodes.Heartbeat then
			-- https://discord.com/developers/docs/topics/gateway-events#heartbeat
			self.logger:info(`received heartbeat request, responding.`)
			self:heartbeatAsync(true):poll()
		elseif payload.op == apiTypes.gateway.opcodes.Reconnect then
			-- https://discord.com/developers/docs/topics/gateway-events#reconnect
			self.logger:info(`received reconnection request, reconnecting..`)

			if self.socketReconnecting then
				self.sessionOutcome = "ReconnectRequested"
			else
				self:_reconnectAutomatically("op 7", self.socketGeneration)
			end
		elseif payload.op == apiTypes.gateway.opcodes.InvalidSession then
			-- https://discord.com/developers/docs/topics/gateway-events#invalid-session
			local messageObject = payload :: apiTypes.InvalidSessionPayload
			local resumable = messageObject.d

			self.logger:info(`discord returned invalid session (resumable: {resumable})`)
			self.sessionOutcome = if resumable then "InvalidResumable" else "InvalidSession"

			if not resumable then
				self:_dropSession()
			end

			if not self.socketReconnecting then
				self:_reconnectAutomatically("op 9", self.socketGeneration)
			end
		elseif payload.op == apiTypes.gateway.opcodes.Hello then
			-- https://discord.com/developers/docs/topics/gateway-events#hello
			local messageObject = payload :: apiTypes.HelloPayload
			local socket = self.socketInstance

			self.logger:info(`received hello message, starting heartbeat..`)
			self.heartbeatInterval = messageObject.d.heartbeat_interval

			future.Future
				.new(function()
					stdPolyfills.task.wait(math.random())

					if not self:_isCurrentSocket(socket) then
						return
					end

					self:heartbeatAsync(true):await()

					if not self:_isCurrentSocket(socket) then
						return
					end

					self:heartbeatIn(messageObject.d.heartbeat_interval)
				end)
				:poll()
		elseif payload.op == apiTypes.gateway.opcodes.HeartbeatACK then
			-- https://discord.com/developers/docs/topics/gateway#heartbeat-interval
			self.heartbeatAcknowledged = true
			self.heartbeatPing = os.clock() - self.heartbeatClockTime :: number

			self.logger:info(
				`received heartbeat acknowledgement, ping: '{string.sub(tostring(self.heartbeatPing), 1, 7)}'`
			)

			self.onSocketHeartbeat:invoke(self.heartbeatPing)

			if not self.socketIdentified then
				self.socketIdentified = true

				if self.sessionId then
					self:sendResumeAsync():poll()
				else
					self.logger:debug(`hasn't identified yet, identifying..`)
					self:identifyAsync():poll()
				end
			end
		end
	end)

	self.onSocketDispatch:listen(function(payload)
		if payload.t == apiTypes.gateway.receiveEvents.Resumed then
			self.sessionOutcome = "Resumed"
			self.logger:notice(`has resumed!`)

			return
		end

		if payload.t ~= apiTypes.gateway.receiveEvents.Ready then
			return
		end

		local message = payload :: apiTypes.ReadyPayload

		self.sessionGateway = message.d.resume_gateway_url
		self.sessionId = message.d.session_id
		self.sessionOutcome = "Ready"

		self.onSocketReady:invoke()
		self.logger:info(`ready! identified as {message.d.user.username}#{message.d.user.discriminator}`)
	end)

	return self
end

type SessionOutcome = "Ready" | "Resumed" | "ReconnectRequested" | "InvalidResumable" | "InvalidSession"
type LoopOutcome = SessionOutcome | "Closed" | "TimedOut" | "Stopped"
type PassResult = "Succeeded" | "Stopped" | "Failed"

export type Shard = typeof(Shard.Prototype) & {
	token: secret.Secret<string>,
	intents: number,
	shardId: number,
	shardCount: number,
	shouldReconnect: boolean,
	largeThreshold: number?,
	zlibBuffer: accumulator.Accumulator,
	onSocketConnected: emitter.Emitter<()>,
	onSocketReconnected: emitter.Emitter<number?>,
	onSocketDisconnected: emitter.Emitter<number?, boolean?>,
	onSocketHeartbeat: emitter.Emitter<number?>,
	onSocketDispatch: emitter.Emitter<apiTypes.Payload<unknown>>,
	onSocketRawMessage: emitter.Emitter<apiTypes.Payload<unknown>>,
	onSocketReady: emitter.Emitter<()>,
	onSocketRateLimited: emitter.Emitter<{ opcode: number, retryAfter: number, guildId: string? }>,
	heartbeatAcknowledged: boolean?,
	heartbeatClockTime: number?,
	heartbeatInterval: number?,
	heartbeatThread: thread?,
	heartbeatPing: number?,
	lastSequence: number?,
	logger: logger.Logger,
	socketActive: boolean,
	socketReconnecting: boolean,
	socketDisconnecting: boolean,
	socketIdentified: boolean,
	stayDisconnected: boolean,
	sessionOutcome: SessionOutcome?,
	closeCode: number?,
	lastIdentifyTimestamp: number?,
	socketGeneration: number,
	rateLimitedGuilds: { [string]: boolean },
	gatewaySendTimestamps: { number },
	sessionId: string?,
	sessionGateway: string?,
	socketVersion: number?,
	socketUrl: string?,
	socketInstance: any?,
	socketThread: thread?,
}

return Shard.Interface
