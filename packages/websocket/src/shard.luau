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
local closeCodes = require("@api-types/gateway/closeCodes")
local gatewayTypes = require("@api-types/gateway/types")

-- selene: allow(bad_string_escape)
local ZLIB_HEADER = "\120\156\141\84"
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
	local isJson, jsonContent = pcall(serde.decode, "json" :: any, message)

	if isJson then
		self.logger:debug(`Shard '{self.shardId}' received message: #{string.len(message)}`)

		self.onSocketRawMessage:invoke(jsonContent)
	else
		self.zlibBuffer:write(message)

		if string.len(message) < 4 or string.sub(message, 1, 4) ~= ZLIB_HEADER then
			self.logger:debug(`Shard '{self.shardId}' received partial message: #{string.len(message)}`)

			return
		end

		self.logger:debug(`Shard '{self.shardId}' received complete message: #{string.len(message)}, decompressing...`)

		local compressedData: string = self.zlibBuffer:flush()
		local success0, response0 = pcall(serde.decompress, "zlib" :: any, compressedData)

		if success0 then
			self.logger:debug(`Shard '{self.shardId}' decompressed Shard message: #{string.len(response0)}`)

			local success1, response1 = pcall(serde.decode, "json" :: any, response0)

			if success1 then
				self.onSocketRawMessage:invoke(response1)
			else
				self.logger:error(`Shard '{self.shardId}' failed to decode Shard JSON message: {response1}`)
			end
		else
			self.logger:error(`Shard '{self.shardId}' failed to decompress Shard ZLIB message: {response0}`)
		end
	end
end

--[[
	Sends a heartbeat to the Discord Gateway API.
]]
function Shard.Prototype.heartbeatAsync(self: Shard, requested: boolean?): future.Future<nil>
	return future.new(function()
		if not self.heartbeatAcknowledged and not requested then
			self.logger:warn(`Shard '{self.shardId}' discord WebSocket state has become Zombified, reconnecting...`)

			self:reconnectAsync():await()
		end

		self.heartbeatClockTime = os.clock()
		self.heartbeatAcknowledged = false

		self.logger:debug(`Shard '{self.shardId}' sending heartbeat request`)

		self:sendAsync(net.jsonEncode({
			["op"] = opcodes.Heartbeat,
			["d"] = self.lastSequence or false,
		}, true)):await()
	end)
end

--[[
	Identifies the current shard with the Discord Gateway.
]]
function Shard.Prototype.identifyAsync(self: Shard): future.Future<nil>
	return future.new(function()
		self.logger:debug(`Shard '{self.shardId}' sending identify request`)

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
		self.logger:debug(`Shard '{self.shardId}' requesting disconnect: {code or 0}`)

		self.onSocketDisconnected:invoke(code)

		if self.socketInstance then
			self.socketInstance.close(code)
		end

		if self.socketThread then
			task.cancel(self.socketThread)
		end

		self.socketActive = false
		self.socketInstance = nil

		self.logger:debug(`Shard '{self.shardId}' disconnected.`)
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
		assert(not self.socketActive, `Shard '{self.shardId}' already connected to a socket.`)

		self.logger:debug(`Shard '{self.shardId}' connecting to: {`{socketUrl}/?v={socketVersion}`}`)

		local success0, response0 = pcall(net.socket, `{socketUrl}/?v={socketVersion}`)

		assert(success0, response0)

		if not self.socketVersion then
			self.socketVersion = socketVersion
		end

		if not self.socketUrl then
			self.socketUrl = socketUrl
		end

		self.socketInstance = response0
		self.socketActive = true

		self.logger:debug(`Shard '{self.shardId}' has connected to: {socketUrl}, starting receive thread.`)

		self.socketThread = task.defer(function()
			self.logger:debug(`Shard '{self.shardId}' Receive thread started, awaiting messages.`)

			self.onSocketConnected:invoke()

			while self.socketActive do
				assert(self.socketInstance, `Socket instance is nil.`)

				if self.socketInstance.closeCode then
					self.logger:warn(`Shard '{self.shardId}' closed from server: {self.socketInstance.closeCode}`)

					self.onSocketDisconnected:invoke(self.socketInstance.closeCode)

					self.socketActive = false
					self.socketInstance = nil
				else
					local success, response = pcall(self.socketInstance.next)

					if success and response then
						self:_handleMessage(response :: string)
					else
						self.logger:warn(
							`Shard '{self.shardId}' error during receive: {response and response or "No error provided, see close code"}`
						)

						self.onSocketDisconnected:invoke(self.socketInstance.closeCode)

						self.socketActive = false
						self.socketInstance = nil
					end
				end
			end

			self.socketThread = nil
			self.logger:debug(`Shard '{self.shardId}' socket has disconnected, receive thread stopped.`)
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
				self.logger:debug(`Shard '{self.shardId}' attempting to resume..`)

				self:sendAsync(net.jsonEncode({
					["op"] = opcodes.Resume,
					["d"] = {
						["token"] = self.token,
						["session_id"] = self.sessionId,
						["seq"] = self.lastSequence,
					},
				}, true)):after(function()
					self.logger:debug(`Shard '{self.shardId}' has resumed!`)
				end)
			end)
			:catch(function(exception)
				self.logger:critical(`Shard '{self.shardId}' failed to resume session: {exception}`)
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
		if self.sessionGateway then
			self.logger:debug(`Shard '{self.shardId}' reconnection requested, reconnecting..`)

			self:disconnectAsync(1012)
				:after(function()
					task.wait(math.random())

					self:resumeAsync()
						:after(function()
							self.logger:debug(`Shard '{self.shardId}' reconnection successful`)
						end)
						:await()
				end)
				:await()
		else
			self.logger:warn(`Shard '{self.shardId}' failed to reconnect! Re-instantiating instead!`)

			self:reinstantiateAsync():await()
		end
	end)
end

--[[
	Sends a message through the WebSocket to Discords Gateway.

	NOTE: Messages are expected to be JSON encoded strings.
]]
function Shard.Prototype.sendAsync(self: Shard, data: string): future.Future<nil>
	local debugTraceback = debug.traceback()

	return future.new(function()
		assert(self.socketActive and self.socketInstance, `Shard '{self.shardId}' not connected to a socket.`)

		self.logger:debug(`Shard '{self.shardId}' sending message of length: {string.len(data)}`)

		local success, response: string? = pcall(self.socketInstance.send, data, true)

		if not success then
			self.socketActive = false
			self.socketInstance = nil

			self.logger:warn(`Shard '{self.shardId}' error during send: {response}\nTraceback: {debugTraceback}`)

			self.onSocketDisconnected:invoke(self.socketInstance.closeCode)
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
		self.logger:debug(`Shard '{self.shardId}' re-instantiation requested..`)

		self:disconnectAsync(1012)
			:after(function()
				task.wait(math.random())

				self:connectAsync(self.socketUrl :: string, self.socketVersion :: number)
					:after(function()
						self.logger:warn(
							`Shard '{self.shardId}' re-instantiation successful, shard {self.shardId} has recovered.`
						)
					end)
					:catch(function(exception1)
						self.logger:emergency(
							`Shard '{self.shardId}' exception during re-instantiation, shard {self.shardId} is now dead! \n{exception1}`
						)
					end)
			end)
			:await()
	end)
end

--[[
	Sends a heartbeat after `milliseconds` milliseconds, looping and continuing to heartbeat 
	until the shard is disconnected.
]]
function Shard.Prototype.heartbeatIn(self: Shard, milliseconds: number): ()
	if self.heartbeatThread then
		task.cancel(self.heartbeatThread)
	end

	self.logger:debug(`Shard '{self.shardId}' to heartbeat in '{milliseconds}' ms`)

	self.heartbeatThread = task.delay(milliseconds / 1000, function()
		self.heartbeatThread = nil

		self:heartbeatAsync()
			:after(function()
				self:heartbeatIn(milliseconds)
			end)
			:catch(function(exception)
				self:disconnectAsync(1011):after(function()
					self.logger:critical(`Shard '{self.shardId}' exception during heartbeat: {exception}`)
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

			onSocketConnected = emitter.new(),
			onSocketReconnected = emitter.new(),
			onSocketDisconnected = emitter.new(),

			onSocketHeartbeat = emitter.new(),

			onSocketDispatch = emitter.new(),
			onSocketRawMessage = emitter.new(),

			logger = logger.new(`Shard<{settings.shardId}>`),

			socketActive = false,
		} :: Shard,
		{ __index = Shard.Prototype }
	)

	-- The following handles "raw" payload/messages from the Discord Websocket.
	self.onSocketRawMessage:listen(function(payload)
		if payload.op == opcodes.Dispatch then
			-- https://discord.com/developers/docs/topics/gateway#dispatch-events

			self.logger:debug(`Shard '{self.shardId}' received dispatch message: {payload.t}`)

			self.lastSequence = payload.s

			self.onSocketDispatch:invoke(payload)
		elseif payload.op == opcodes.Heartbeat then
			-- https://discord.com/developers/docs/topics/gateway-events#heartbeat

			self.logger:debug(`Shard '{self.shardId}' received heartbeat request, responding.`)
			self:heartbeatAsync(true)
		elseif payload.op == opcodes.Reconnect then
			-- https://discord.com/developers/docs/topics/gateway-events#reconnect

			self:reconnectAsync()
		elseif payload.op == opcodes.InvalidSession then
			-- https://discord.com/developers/docs/topics/gateway-events#invalid-session

			local messageObject = payload :: gatewayTypes.InvalidSessionPayload

			self.logger:warn(`Shard '{self.shardId}' discord returned invalid session, reconnecting..`)

			if messageObject.d then
				self.logger:warn(`Shard '{self.shardId}' discord invalid session is recoverable, resuming session..`)

				self:reconnectAsync():catch(function(exception0)
					self.logger:warn(
						`Shard '{self.shardId}' unrecoverable error during reconnection, re-instantiating shard.. \n{exception0}`
					)

					self:reinstantiateAsync()
				end)
			else
				self.logger:warn(
					`Shard '{self.shardId}' unrecoverable error during connection, re-instantiating shard..`
				)

				self:reinstantiateAsync()
			end
		elseif payload.op == opcodes.Hello then
			-- https://discord.com/developers/docs/topics/gateway-events#hello

			self.logger:debug(`Shard '{self.shardId}' received hello message, starting heartbeat..`)

			local messageObject = payload :: gatewayTypes.HelloPayload

			self.heartbeatInterval = messageObject.d.heartbeat_interval

			task.wait(math.random())

			self:heartbeatAsync(true)
				:after(function()
					self:heartbeatIn(self.heartbeatInterval :: number)
				end)
				:catch(function(exception)
					self:disconnectAsync(1011):after(function()
						self.logger:critical(`Exception during initial heartbeat: {exception}`)
					end)
				end)
		elseif payload.op == opcodes.HeartbeatACK then
			-- https://discord.com/developers/docs/topics/gateway#heartbeat-interval

			self.logger:debug(`Shard '{self.shardId}' received heartbeat acknowledgement.`)

			self.heartbeatAcknowledged = true
			self.heartbeatPing = os.clock() - self.heartbeatClockTime :: number

			self.onSocketHeartbeat:invoke(self.heartbeatPing)

			if not self.hasIdentified then
				self.hasIdentified = true

				self.logger:debug(`Shard '{self.shardId}' hasn't identified yet, identifying..`)

				self:identifyAsync():catch(function(exception)
					self.hasIdentified = nil

					self.logger:critical(`Shard '{self.shardId}' exception during initial identify: {exception}`)
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
	self.onSocketDispatch:listen(function(payload)
		if payload.t ~= receiveEvents.Ready then
			return
		end

		local message = payload :: gatewayTypes.ReadyPayload

		self.sessionGateway = message.d.resume_gateway_url
		self.sessionId = message.d.session_id

		self.logger:debug(
			`Shard '{self.shardId}' has identified as {message.d.user.username}#{message.d.user.discriminator}`
		)
	end)

	self.onSocketDisconnected:listen(function(code)
		if self.heartbeatThread then
			task.cancel(self.heartbeatThread)
		end

		if code == closeCodes.UnknownError then
			self:reconnectAsync()
		elseif code == closeCodes.UnknownOpcode then
			self:reconnectAsync()
		elseif code == closeCodes.DecodeError then
			self:reconnectAsync()
		elseif code == closeCodes.NotAuthenticated then
			self.logger:error(
				`Shard '{self.shardId}', Something has gone terribly wrong with Discord-Luau.. please create an issue! [{code}]`
			)
		elseif code == closeCodes.AuthenticationFailed then
			self.logger:warn(
				`Shard '{self.shardId}', Failed to authenticate with the Discord API, is your token correct?`
			)
		elseif code == closeCodes.AlreadyAuthenticated then
			self:reconnectAsync()
		elseif code == closeCodes.InvalidSeq then
			self:reconnectAsync()
		elseif code == closeCodes.Ratelimited then
			self:reconnectAsync()
		elseif code == closeCodes.SessionTimedOut then
			self:reconnectAsync()
		elseif code == closeCodes.InvalidShard then
			self.logger:error(
				`Shard '{self.shardId}', Something has gone terribly wrong with Discord-Luau.. please create an issue! [{code}]`
			)
		elseif code == closeCodes.InvalidAPIVersion then
			self.logger:error(
				`Shard '{self.shardId}', Something has gone terribly wrong with Discord-Luau.. please create an issue! [{code}]`
			)
		elseif code == closeCodes.InvalidIntents then
			self.logger:error(
				`Shard '{self.shardId}', Something has gone terribly wrong with Discord-Luau.. please create an issue! [{code}]`
			)
		elseif code == closeCodes.DisallowedIntents then
			self.logger:warn(
				`Shard '{self.shardId}', intent '{self.intents}' are invalid, are you sure the bot has the chosen intents enabled?`
			)
		else
			self.logger:warn(`Unknown close code: '{code}' - will attempt to resume Shard '{self.shardId}'`)
			self.logger:info(
				`If you have the time, please create an issue on the Discord-Luau repository! This is not normal behaviour!`
			)

			self:reconnectAsync()
		end
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

	onSocketConnected: emitter.Emitter<()>,
	onSocketReconnected: emitter.Emitter<number?>,
	onSocketDisconnected: emitter.Emitter<number?>,

	onSocketHeartbeat: emitter.Emitter<number?>,

	onSocketDispatch: emitter.Emitter<gatewayTypes.Payload<unknown>>,
	onSocketRawMessage: emitter.Emitter<gatewayTypes.Payload<unknown>>,

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
