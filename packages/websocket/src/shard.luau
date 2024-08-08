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

-- selene: allow(bad_string_escape)
local ZLIB_HEADER = "\x00\x00\xff\xff"
local LIBRARY_IDENTIFIER = "DiscordLuau"

--[[
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
	5. Handling reconnection logic when the connection becomes unstable or "zombified"
	6. Providing an interface for other parts of the application to interact with the WebSocket connection

	The Shard module is crucial for maintaining real-time communication with Discord's Gateway,
	ensuring the bot stays connected and can send and receive updates efficiently.
]]
local Shard = {}

Shard.Interface = {}
Shard.Prototype = {}

--[[
	Function responsible for handling incoming messages from the WebSocket connection.
	
	It performs the following steps:
	1. Decompresses the incoming message if it's ZLIB-compressed
		i. It's worth noting that payloads may not be complete, meaning we should add data to the
			buffer until we have a complete message
	2. Decodes the JSON payload
	3. Invokes the appropriate callback based on the received event type

	Roughly based on the following documentation:
	https://discord.com/developers/docs/topics/gateway#zlibstream
]]
function Shard.Prototype._handleMessage(self: Shard, message: string): ()
	self.zlibBuffer:write(message)

	if string.len(message) < 4 or string.sub(message, 1, 4) ~= ZLIB_HEADER then
		self.logger:debug(`Received partial message: #{string.len(message)}`)

		return
	end

	self.logger:debug(`Received complete message: #{string.len(message)}, decompressing...`)

	local compressedData: string = self.zlibBuffer:flush()
	local success0, response0 = pcall(serde.decompress, "zlib" :: any, compressedData)

	if success0 then
		self.logger:debug(`Decompressed Shard message: #{string.len(response0)}`)

		local success1, response1 = pcall(serde.decode, "json" :: any, response0)

		if success1 then
			self.onSocketRawMessage:invoke(response1)
		else
			self.logger:error(`Failed to decode Shard JSON message: {response1}`)
		end
	else
		self.logger:error(`Failed to decompress Shard ZLIB message: {response0}`)
	end
end

--[[
	Sends a heartbeat to the Discord Gateway API.
]]
function Shard.Prototype.heartbeatAsync(self: Shard, requested: boolean?): future.Future<nil>
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

--[[
	Identifies the current shard with the Discord Gateway.
]]
function Shard.Prototype.identifyAsync(self: Shard): future.Future<nil>
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

--[[
	Disconnects the Shard from the Discord Gateway.

	Optionally, a WebSocket close code can be provided, websocket close code spec can be found here:
	https://developer.mozilla.org/en-US/docs/Web/API/CloseEvent/code
]]
function Shard.Prototype.disconnectAsync(self: Shard, code: number?): future.Future<nil>
	return future.new(function()
		assert(self.socketActive and self.socketInstance, `expected socket to be connected.`)
		assert(self.socketThread, `expected socket thread to be set.`)

		self.logger:debug(`Shard requesting disconnect: {code or 0}`)

		self.socketInstance.close(code)

		task.cancel(self.socketThread)

		self.socketActive = false
		self.socketInstance = nil

		self.logger:debug(`Shard disconnected.`)
	end)
end

--[[
	Connects the shard to a Discord Gateway.

	Expects both a Socket URL, and Socket Version to be provided. It will prepend the socket version
	to the socket URL, and then connect to the socket.

	Also responsible for spawning the thread that will be responsible for
	receiving messages from the socket.
]]
function Shard.Prototype.connectAsync(self: Shard, socketUrl: string, socketVersion: number): future.Future<nil>
	return future.new(function()
		assert(not self.socketActive, `Shard already connected to a socket.`)

		self.logger:debug(`Shard connecting to: {socketUrl}`)

		local success0, response0 = pcall(net.socket, socketUrl)

		assert(success0, response0)

		self.socketVersion = self.socketVersion
		self.socketUrl = `{socketUrl}/?v={socketVersion}`
		self.socketInstance = response0
		self.socketActive = true

		self.logger:debug(`Shard has connected to: {socketUrl}, starting receive thread.`)

		self.socketThread = task.defer(function()
			self.logger:debug(`Receive thread started, awaiting messages.`)

			while self.socketActive do
				assert(self.socketInstance, `Socket instance is nil.`)

				if self.socketInstance.closeCode then
					self.socketActive = false
					self.socketInstance = nil

					self.logger:warn(`Shard closed from server: {self.socketInstance.closeCode}`)

					self.onSocketClose:invoke(self.socketInstance.closeCode)
				else
					local success, response = pcall(self.socketInstance.next)

					if success then
						self:_handleMessage(response :: string)
					else
						self.socketActive = false
						self.socketInstance = nil

						self.logger:warn(`Shard error during receive: {response}`)

						self.onSocketClose:invoke(self.socketInstance.closeCode)
					end
				end
			end

			self.logger:debug(`Socket has disconnected, receive thread stopped.`)
		end)
	end)
end

--[[
	Resumes a shard session if for some reason the session has either become
	zombified, or the session has been invalidated by Discord.
]]
function Shard.Prototype.resumeAsync(self: Shard): future.Future<nil>
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
				self.logger:critical(`Shard failed to resumme session: {exception}`)
			end)
			:await()
	end)
end

--[[
	Closes the websocket connection and reconnects the shard.
	This is not a re-instantiation of the shard, but a re-connection of the shard.
]]
function Shard.Prototype.reconnectAsync(self: Shard): future.Future<nil>
	return future.new(function()
		self:disconnectAsync(1012)
			:after(function()
				task.wait(math.random())

				self:resumeAsync():await()
			end)
			:await()
	end)
end

--[[
	Sends a message through the WebSocket to Discords Gateway.

	NOTE: Messages are expected to be JSON encoded strings.
]]
function Shard.Prototype.sendAsync(self: Shard, data: string): future.Future<nil>
	local debugTraceback = debug.traceback()

	return future.new(function()
		assert(self.socketActive and self.socketInstance, `Shard not connected to a socket.`)

		self.logger:warn(`Sending Shard message of length: {string.len(data)}`)

		local success, response: string? = pcall(self.socketInstance.send, data, false)

		if not success then
			self.socketActive = false
			self.socketInstance = nil

			self.logger:warn(`Shard error during send: {response}\nTraceback: {debugTraceback}`)

			self.onSocketClose:invoke(self.socketInstance.closeCode)
		end
	end)
end

--[[
	Disconnects the Shard, and re-instantiats it.

	Re-instantiation is the reconnection of the shard to the original socket passed, and not the
	session URL/ID that was passed.

	Any events between the initial disconnection and reconnection will not be recovered. If this is
	what you intend to do, use `Shard:reconnectAsync` instead.
]]
function Shard.Prototype.reinstantiateAsync(self: Shard): future.Future<nil>
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

--[[
	Sends a heartbeat after `t` milliseconds, looping and continuing to heartbeat 
	until the shard is disconnected.
]]
function Shard.Prototype.heartbeatIn(self: Shard, t: number): ()
	if self.heartbeatThread then
		task.cancel(self.heartbeatThread)
	end

	self.heartbeatThread = task.delay(t / 1000, function()
		self.heartbeatThread = nil

		self:heartbeatAsync()
			:after(function()
				self:heartbeatIn(t)
			end)
			:catch(function(exception)
				self:disconnectAsync(1011):after(function()
					self.logger:critical(`Exception during heartbeat: {exception}`)
				end)
			end)
	end)
end

--[[
	Constructor function for Shard.
]]
function Shard.Interface.new(settings: {
	token: string,

	intents: number,
	shardId: number,
	shardCount: number,

	largeThreshold: number?,
}): Shard
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

			logger = logger.new(`Shard<{settings.shardId}>`),

			socketActive = false,
		} :: Shard,
		{ __index = Shard.Prototype }
	)

	-- The following handles "raw" payload/messages from the Discord Websocket.
	self.onSocketRawMessage:listen(function(payload)
		if payload.op == opcodes.Dispatch then
			-- https://discord.com/developers/docs/topics/gateway#dispatch-events

			self.logger:debug(`Shard received dispatch message: {payload.t}`)

			self.lastSequence = payload.s

			self.onSocketDispatch:invoke(payload.t, payload.d)
		elseif payload.op == opcodes.Heartbeat then
			-- https://discord.com/developers/docs/topics/gateway-events#heartbeat

			self.logger:debug(`Shard received heartbeat request, responding.`)
			self:heartbeatAsync(true)
		elseif payload.op == opcodes.Reconnect then
			-- https://discord.com/developers/docs/topics/gateway-events#reconnect

			self:reconnectAsync()
		elseif payload.op == opcodes.InvalidSession then
			-- https://discord.com/developers/docs/topics/gateway-events#invalid-session

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
			-- https://discord.com/developers/docs/topics/gateway-events#hello

			self.logger:debug(`Shard received hello message, starting heartbeat..`)

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
			-- https://discord.com/developers/docs/topics/gateway#heartbeat-interval

			self.logger:debug(`Shard received heartbeat acknowledgement.`)

			self.heartbeatAcknowledged = true
			self.heartbeatPing = os.clock() - self.heartbeatClockTime :: number

			if not self.hasIdentified then
				self.hasIdentified = true

				self.logger:debug(`Shard hasn't identified yet, identifying..`)

				self:identifyAsync():catch(function(exception)
					self.hasIdentified = nil

					self.logger:critical(`Exception during initial identify: {exception}`)
				end)
			end
		end
	end)

	--[[
		The following handles events from the Discord Websocket, we're specifically awaiting the 'Ready'
			event, which is emitted when the shard has identified.

		The Ready event contains the resume gateway url, and the session id, which is key for us
			in order to resume the session.
	]]
	self.onSocketDispatch:listen(function(event, payload)
		if event ~= receiveEvents.Ready then
			return
		end

		local message = payload :: gatewayTypes.ReadyPayload

		self.sessionGateway = message.d.resume_gateway_url
		self.sessionGateway = message.d.session_id

		self.logger:debug(`Shard has identified as {message.d.user.username}#{message.d.user.discriminator}`)
	end)

	return self
end

export type Shard = typeof(Shard.Prototype) & {
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

return Shard.Interface
