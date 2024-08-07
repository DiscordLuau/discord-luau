local net = require("@std-polyfills/net")
local task = require("@std-polyfills/task")
local serde = require("@std-polyfills/serde")
local process = require("@std-polyfills/process")

local logger = require("@vendor/logger")
local future = require("@vendor/future")
local buffer = require("@vendor/buffer")
local emitter = require("@vendor/emitter")

local receiveEvents = require("@api-types/gateway/receiveEvents")
local opcodes = require("@api-types/gateway/opcodes")
local gatewayTypes = require("@api-types/gateway/types")

local ZLIB_HEADER = "\x00\x00\xff\xff"
local LIBRARY_IDENTIFIER = "DiscordLuau"

local WebSocketShard = {}

WebSocketShard.Interface = {}
WebSocketShard.Prototype = {}

function WebSocketShard.Prototype._handleMessage(self: WebSocketShard, message: string): ()
	self.zlibBuffer:write(message)

	if string.len(message) < 4 or string.sub(message, 1, 4) ~= ZLIB_HEADER then
		self.logger:debug(`Received partial message: #{string.len(message)}`)

		return
	end

	self.logger:debug(`Received complete message: #{string.len(message)}, decompressing...`)

	local compressedData: string = self.zlibBuffer:flush()
	local success0, response0 = pcall(serde.decompress, "zlib" :: any, compressedData)

	if success0 then
		self.logger:debug(`Decompressed WebSocketShard message: #{string.len(response0)}`)

		local success1, response1 = pcall(serde.decode, "json" :: any, response0)

		if success1 then
			self.onSocketRawMessage:invoke(response1)
		else
			self.logger:error(`Failed to decode WebSocketShard JSON message: {response1}`)
		end
	else
		self.logger:error(`Failed to decompress WebSocketShard ZLIB message: {response0}`)
	end
end

function WebSocketShard.Prototype.heartbeatAsync(self: WebSocketShard, requested: boolean?): future.Future<nil>
	return future.new(function()
		if not self.heartbeatAcknowledged and not requested then
			self.logger:warn(`Discord WebSocket state has become Zombified, reconnecting...`)

			self:reconnectAsync()
		end

		self.heartbeatClockTime = os.clock()
		self.heartbeatAcknowledged = false

		self:sendAsync(net.jsonEncode({
			["op"] = opcodes.Heartbeat,
			["d"] = self.lastSequence,
		}, true)):await()
	end)
end

function WebSocketShard.Prototype.identifyAsync(self: WebSocketShard): future.Future<nil>
	return future.new(function()
		self:sendAsync(net.jsonEncode({
			["op"] = opcodes.Identify,
			["d"] = {
				["token"] = self.token,
				["intents"] = self.intents,
				["compress"] = true,
				["large_threshold"] = self.largeThreshold or 250,
				["shard"] = {
					self.shardId,
					self.shardCount,
				},
				["properties"] = {
					["os"] = process.os,
					["browser"] = LIBRARY_IDENTIFIER,
					["device"] = LIBRARY_IDENTIFIER,
				},
			},
		}, true)):await()
	end)
end

function WebSocketShard.Prototype.disconnectAsync(self: WebSocketShard, code: number?): future.Future<nil>
	return future.new(function()
		assert(self.socketActive and self.socketInstance, `expected socket to be connected.`)
		assert(self.socketThread, `expected socket thread to be set.`)

		self.logger:debug(`WebSocketShard requesting disconnect: {code or 0}`)

		self.socketInstance.close(code)

		task.cancel(self.socketThread)

		self.socketActive = false
		self.socketInstance = nil

		self.logger:debug(`WebSocketShard disconnected.`)
	end)
end

function WebSocketShard.Prototype.connectAsync(
	self: WebSocketShard,
	socketUrl: string,
	socketVersion: number
): future.Future<nil>
	return future.new(function()
		assert(not self.socketActive, `WebSocketShard already connected to a socket.`)

		self.logger:debug(`WebSocketShard connecting to: {socketUrl}`)

		local success0, response0 = pcall(net.socket, socketUrl)

		assert(success0, response0)

		self.socketVersion = self.socketVersion
		self.socketUrl = `{socketUrl}/?v={socketVersion}`
		self.socketInstance = response0
		self.socketActive = true

		self.logger:debug(`WebSocketShard has connected to: {socketUrl}, starting receive thread.`)

		self.socketThread = task.defer(function()
			self.logger:debug(`Receive thread started, awaiting messages.`)

			while self.socketActive do
				assert(self.socketInstance, `Socket instance is nil.`)

				if self.socketInstance.closeCode then
					self.socketActive = false
					self.socketInstance = nil

					self.logger:warn(`WebSocketShard closed from server: {self.socketInstance.closeCode}`)

					self.onSocketClose:invoke(self.socketInstance.closeCode)
				else
					local success, response = pcall(self.socketInstance.next)

					if success then
						self:_handleMessage(response :: string)
					else
						self.socketActive = false
						self.socketInstance = nil

						self.logger:warn(`WebSocketShard error during receive: {response}`)

						self.onSocketClose:invoke(self.socketInstance.closeCode)
					end
				end
			end

			self.logger:debug(`Socket has disconnected, receive thread stopped.`)
		end)
	end)
end

function WebSocketShard.Prototype.resumeAsync(self: WebSocketShard): future.Future<nil>
	return future.new(function()
		self:connectAsync(self.sessionGateway :: string, self.socketVersion :: number)
			:after(function()
				self:sendAsync(net.jsonEncode({
					["op"] = opcodes.Resume,
					["d"] = {
						["token"] = self.token,
						["session_id"] = self.sessionId,
						["seq"] = self.lastSequence,
					},
				}, true)):await()
			end)
			:catch(function(exception)
				self.logger:critical(`WebSocketShard failed to resumme session: {exception}`)
			end)
			:await()
	end)
end

function WebSocketShard.Prototype.reconnectAsync(self: WebSocketShard): future.Future<nil>
	return future.new(function()
		self:disconnectAsync(1012)
			:after(function()
				task.wait(math.random())

				self:resumeAsync():await()
			end)
			:await()
	end)
end

function WebSocketShard.Prototype.sendAsync(self: WebSocketShard, data: string): future.Future<nil>
	local debugTraceback = debug.traceback()

	return future.new(function()
		assert(self.socketActive and self.socketInstance, `WebSocketShard not connected to a socket.`)

		self.logger:warn(`Sending WebSocketShard message of length: {string.len(data)}`)

		local success, response: string? = pcall(self.socketInstance.send, data, false)

		if not success then
			self.socketActive = false
			self.socketInstance = nil

			self.logger:warn(`WebSocketShard error during send: {response}\nTraceback: {debugTraceback}`)

			self.onSocketClose:invoke(self.socketInstance.closeCode)
		end
	end)
end

function WebSocketShard.Prototype.reinstantiateAsync(self: WebSocketShard): future.Future<nil>
	return future.new(function()
		self:disconnectAsync(1012)
			:after(function()
				task.wait(math.random())

				self:connectAsync(self.socketUrl :: string, self.socketVersion :: number)
					:after(function()
						self.logger:warn(`Re-instantiation successful, shard {self.shardId} has recovered.`)
					end)
					:catch(function(exception1)
						self.logger:emergency(
							`Exception during re-instantiation, shard {self.shardId} is now dead! \n{exception1}`
						)
					end)
			end)
			:await()
	end)
end

function WebSocketShard.Prototype.heartbeatIn(self: WebSocketShard, milliseconds: number): ()
	if self.heartbeatThread then
		task.cancel(self.heartbeatThread)
	end

	self.heartbeatThread = task.delay(milliseconds / 1000, function()
		self.heartbeatThread = nil

		self:heartbeatAsync()
			:after(function()
				self:heartbeatIn(milliseconds)
			end)
			:catch(function(exception)
				self:disconnectAsync(1011):after(function()
					self.logger:critical(`Exception during heartbeat: {exception}`)
				end)
			end)
	end)
end

function WebSocketShard.Interface.new(settings: {
	token: string,

	intents: number,
	shardId: number,
	shardCount: number,

	largeThreshold: number?,
}): WebSocketShard
	local self = setmetatable(
		{
			token = settings.token,
			intents = settings.intents,
			shardId = settings.shardId,
			shardCount = settings.shardCount,

			largeThreshold = settings.largeThreshold,

			zlibBuffer = buffer.new(),

			onSocketDispatch = emitter.new(),
			onSocketRawMessage = emitter.new(),

			onSocketClose = emitter.new(),

			logger = logger.new(`WebSocketShard<{settings.shardId}>`),

			socketActive = false,
		} :: WebSocketShard,
		{ __index = WebSocketShard.Prototype }
	)

	self.onSocketRawMessage:listen(function(payload)
		if payload.op == opcodes.Dispatch then
			self.logger:debug(`WebSocketShard received dispatch message: {payload.t}`)

			self.onSocketDispatch:invoke(payload.t, payload.d)
		elseif payload.op == opcodes.Heartbeat then
			self.logger:debug(`WebSocketShard received heartbeat request, responding.`)

			self:heartbeatAsync(true)
		elseif payload.op == opcodes.Reconnect then
			self:reconnectAsync()
		elseif payload.op == opcodes.InvalidSession then
			local messageObject = payload :: gatewayTypes.InvalidSessionPayload

			self.logger:warn(`Discord returned invalid session, reconnecting..`)

			if messageObject.d then
				self.logger:warn(`Discord invalid session is recoverable, resuming session..`)

				self:reconnectAsync():catch(function(exception0)
					self.logger:warn(`Unrecoverable error during reconnection, re-instantiating shard.. \n{exception0}`)

					self:reinstantiateAsync()
				end)
			else
				self.logger:warn("Unrecoverable error during connection, re-instantiating shard..")

				self:reinstantiateAsync()
			end
		elseif payload.op == opcodes.Hello then
			self.logger:debug(`WebSocketShard received hello message, starting heartbeat..`)

			local messageObject = payload :: gatewayTypes.HelloPayload

			task.wait(math.random())

			self.heartbeatInterval = messageObject.d.heartbeat_interval

			self:heartbeatAsync(true)
				:after(function()
					self:heartbeatIn(self.heartbeatInterval :: number)
				end)
				:catch(function(exception)
					self:disconnectAsync(1011):after(function()
						self.logger:critical(`Exception during initial heartbeat: {exception}`)
					end)
				end)

			self.logger:warn(`Handler for shard {payload.op} not implemented.`)
		elseif payload.op == opcodes.HeartbeatACK then
			self.logger:debug(`WebSocketShard received heartbeat acknowledgement.`)

			self.heartbeatAcknowledged = true
			self.heartbeatPing = os.clock() - self.heartbeatClockTime :: number

			if not self.hasIdentified then
				self.hasIdentified = true

				self.logger:debug(`WebSocketShard hasn't identified yet, identifying..`)

				self:identifyAsync():catch(function(exception)
					self.hasIdentified = nil

					self.logger:critical(`Exception during initial identify: {exception}`)
				end)
			end
		end
	end)

	self.onSocketDispatch:listen(function(event, payload)
		if event ~= receiveEvents.Ready then
			return
		end

		local message = payload :: gatewayTypes.ReadyPayload

		self.sessionGateway = message.d.resume_gateway_url
		self.sessionGateway = message.d.session_id

		self.logger:debug(`WebSocketShard has identified as {message.d.user.username}#{message.d.user.discriminator}`)
	end)

	return self
end

export type WebSocketShard = typeof(WebSocketShard.Prototype) & {
	token: string,
	intents: number,
	shardId: number,
	shardCount: number,

	hasIdentified: boolean?,

	largeThreshold: number?,

	zlibBuffer: buffer.Buffer,

	onSocketDispatch: emitter.Emitter<string, gatewayTypes.Payload<unknown>>,
	onSocketRawMessage: emitter.Emitter<gatewayTypes.Payload<unknown>>,

	onSocketClose: emitter.Emitter<number>,

	heartbeatAcknowledged: boolean?,
	heartbeatClockTime: number?,
	heartbeatInterval: number?,
	heartbeatThread: thread?,
	heartbeatPing: number?,

	lastSequence: number?,

	logger: logger.Logger,

	socketActive: boolean,

	sessionId: string?,
	sessionGateway: string?,

	socketVersion: number?,
	socketUrl: string?,
	socketInstance: net.WebSocket?,
	socketThread: thread?,
}

return WebSocketShard.Interface
