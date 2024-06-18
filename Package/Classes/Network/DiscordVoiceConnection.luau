local Task = require("@Std/Task")

local Future = require("@Vendor/Future")
local Console = require("@Vendor/Console")
local Signal = require("@Vendor/Signal")

local Construct = require("@Utils/Construct")

local DiscordWebsocket = require("@Network/DiscordWebsocket")
local DiscordUDP = require("@Network/DiscordUDP")

local VoiceWebsocketOperationCodes = require("@Enums/VoiceWebsocketOperationCodes")
local VoiceWebsocketCloseCodes = require("@Enums/VoiceWebsocketCloseCodes")
local WebsocketOperationCodes = require("@Enums/WebsocketOperationCodes")
local WebsocketOperationKeys = require("@Enums/WebsocketOperationKeys")
local WebsocketEvents = require("@Enums/WebsocketEvents")

local BASE_VOICE_CONNECTION_PORT = 1050

--[=[
	@class Network.DiscordVoiceConnection

	The `DiscordVoiceConnection` class handles the voice connection functionalities for Discord-Luau. This class is responsible for managing the lifecycle of a voice connection, handling websocket operations, and ensuring proper communication with Discord's voice servers.

	:::caution
	This class is internal and should not be used directly by developers. Instead, use the provided public interfaces and methods to interact with voice connections.
	:::
]=]
local DiscordVoiceConnection = {}

DiscordVoiceConnection.Internal = {}
DiscordVoiceConnection.Interface = {}
DiscordVoiceConnection.Prototype = {}

DiscordVoiceConnection.Prototype.type = "DiscordVoiceConnection"

DiscordVoiceConnection.Prototype.activeConnections = 0

--[=[
	Observes and handles errors from the voice websocket.
	
	@private
	@method observeWebsocketErrors
	@param self DiscordVoiceConnection
	@within Network.DiscordVoiceConnection
]=]
function DiscordVoiceConnection.Prototype.observeWebsocketErrors(self: DiscordVoiceConnection)
	self.voiceWebsocket.onSocketDead:connect(function(closeCode)
		if closeCode == VoiceWebsocketCloseCodes.UnknownError then
			self:reconnectAsync()
		elseif closeCode == VoiceWebsocketCloseCodes.UnknownOperation then
			self:reconnectAsync()
		elseif closeCode == VoiceWebsocketCloseCodes.DecodeError then
			self:reconnectAsync()
		elseif closeCode == VoiceWebsocketCloseCodes.NotAuthenticated then
			self.reporter:error(
				`Something has gone terribly wrong with Discord-Luau.. please create an issue! [{closeCode}]`
			)
		elseif closeCode == VoiceWebsocketCloseCodes.AuthenticationFailed then
			self.reporter:warn(`Failed to authenticate with the Discord Voice Gateway, is your token correct?`)
		elseif closeCode == VoiceWebsocketCloseCodes.AlreadyAuthenticated then
			self:reconnectAsync()
		elseif closeCode == VoiceWebsocketCloseCodes.SessionTimedOut then
			self:reconnectAsync()
		elseif closeCode == VoiceWebsocketCloseCodes.ServerNotFound then
			self.reporter:error(`Voice Websocket unable to find server; '{self.guildId}'`)
		elseif closeCode == VoiceWebsocketCloseCodes.UnknownProtocol then
			self.reporter:error(
				`Something has gone terribly wrong with Discord-Luau.. please create an issue! [{closeCode}]`
			)
		elseif closeCode == VoiceWebsocketCloseCodes.Disconnected then
			self.reporter:debug(`Disconnected from Voice websocket`)
		elseif closeCode == VoiceWebsocketCloseCodes.VoiceServerCrashed then
			self:reconnectAsync()
		elseif closeCode == VoiceWebsocketCloseCodes.UnknownEncryptionMode then
			self.reporter:error(
				`Something has gone terribly wrong with Discord-Luau.. please create an issue! [{closeCode}]`
			)
		end
	end)
end

--[=[
	Observes and handles operations received from the voice websocket.
	
	@private
	@method observeWebsocketOperations
	@param self DiscordVoiceConnection
	@within Network.DiscordVoiceConnection
]=]
function DiscordVoiceConnection.Prototype.observeWebsocketOperations(self: DiscordVoiceConnection)
	self.voiceWebsocket.onOperationRecv:connect(function(operationCode, operationData)
		if operationCode == VoiceWebsocketOperationCodes.Hello then
			Task.wait(math.random())

			self.heartbeatInterval = operationData.heartbeatInterval
			self:heartbeatAsync(true):after(function()
				self:heartbeatIn(self.heartbeatInterval)
			end)
		elseif operationCode == VoiceWebsocketOperationCodes.HeartbeatACK then
			self.heartbeatAck = true
			self.heartbeatPing = os.clock() - self.heartbeatClockTime :: number

			if operationData ~= self.heartbeatNonce then
				self.reporter:warn(`HeartbeatACK - nonce received was incorrect`)
			end

			self.reporter:debug(`HeartbeatACK - Ping: {self.heartbeatPing}`)
		elseif operationCode == VoiceWebsocketOperationCodes.Ready then
			DiscordVoiceConnection.Prototype.activeConnections += 1

			local thread = coroutine.running()

			self.voiceUDP = (
				DiscordUDP.new(
					`0.0.0.0:{BASE_VOICE_CONNECTION_PORT + DiscordVoiceConnection.Prototype.activeConnections}`
				) :: unknown
			) :: DiscordUDP.DiscordUDP

			self.voiceUDP.onMessageRecv:once(function(packetData: string)
				local responseData = { string.unpack(">I2I2I4c64I2", packetData) }

				coroutine.resume(thread, responseData[4])
			end)

			self.voiceUDP:connectAsync(`{operationData.ip}:{operationData.port}`):await()
			self.voiceUDP:sendAsync(
				string.pack(`>I2I2I4c64I2`, 1, 70, operationData.ssrc, operationData.ip, operationData.port)
			)

			local publicIp = coroutine.yield()

			self.voiceWebsocket
				:sendAsync({
					[WebsocketOperationKeys.OperationCode] = VoiceWebsocketOperationCodes.SelectProtocol,
					[WebsocketOperationKeys.Data] = {
						protocol = "udp",
						data = {
							address = publicIp,
							port = BASE_VOICE_CONNECTION_PORT + DiscordVoiceConnection.Prototype.activeConnections,
							mode = "xsalsa20_poly1305",
						},
					},
				})
				:await()
		elseif operationCode == VoiceWebsocketOperationCodes.SessionDescription then
			self.encryptionKey = buffer.create(64)
			self.mediaSessionId = operationData.mediaSessionId

			for index = 1, 32 do
				buffer.writei16(self.encryptionKey, index, operationData.secretKey[tostring(index)])
			end
		end
	end)
end

--[=[
	Sends a heartbeat to the voice websocket and manages the heartbeat acknowledgements.
	
	@private
	@method heartbeatAsync
	@param self DiscordVoiceConnection
	@param ignoreHeartbeatAck boolean? -- Whether to ignore heartbeat acknowledgements.
	@within Network.DiscordVoiceConnection
	@return Vendor.Future
]=]
function DiscordVoiceConnection.Prototype.heartbeatAsync(self: DiscordVoiceConnection, ignoreHeartbeatAck: boolean?)
	return Future.try(function()
		if not ignoreHeartbeatAck then
			if not self.heartbeatAck then
				self.reporter:warn(`Discord Websocket state has become zombified, attempting to reconnect!`)

				self:reconnectAsync():await()
			end

			self.heartbeatAck = nil
		end

		self.heartbeatClockTime = os.clock()
		self.heartbeatNonce = math.random(1_000_000_000)

		self.voiceWebsocket
			:sendAsync({
				[WebsocketOperationKeys.OperationCode] = VoiceWebsocketOperationCodes.Heartbeat,
				[WebsocketOperationKeys.Data] = self.heartbeatNonce,
			})
			:await()
	end)
end

--[=[
	Schedules the next heartbeat to be sent after a specified interval.
	
	@private
	@method heartbeatIn
	@param self DiscordVoiceConnection
	@param milliseconds number -- The interval in milliseconds before the next heartbeat is sent.
	@within Network.DiscordVoiceConnection
]=]
function DiscordVoiceConnection.Prototype.heartbeatIn(self: DiscordVoiceConnection, milliseconds: number)
	if self.heartbeatTask then
		Task.cancel(self.heartbeatTask)
	end

	self.heartbeatTask = Task.delay(milliseconds / 1000, function()
		self.heartbeatTask = nil

		self:heartbeatAsync():await()
		self:heartbeatIn(milliseconds)
	end)
end

--[=[
	Connects to a voice channel asynchronously.
	
	@private
	@method connectAsync
	@param self DiscordVoiceConnection
	@param guildId string
	@param channelId string
	@within Network.DiscordVoiceConnection
	@return Vendor.Future
]=]
function DiscordVoiceConnection.Prototype.connectAsync(self: DiscordVoiceConnection, guildId: string, channelId: string)
	return Future.try(function()
		local guildObject = self.discordClient:fetchGuildAsync(guildId):await()
		local websocket: DiscordWebsocket.DiscordWebsocket =
			self.discordClient.discordShards[guildObject.shardId].discordWebsocket
		local connection

		connection = self.discordClient.discordShards[guildObject.shardId].onEvent:connect(
			function(eventName, data: { [any]: any })
				if eventName == WebsocketEvents.VoiceServerUpdate then
					if data.guildId == guildId then
						self.voiceServerUpdate = data
					end
				elseif eventName == WebsocketEvents.VoiceStateUpdate then
					if data.userId == self.discordClient.discordUser.id then
						self.voiceStateUpdate = data
					end
				end
			end
		)

		websocket
			:sendAsync({
				[WebsocketOperationKeys.OperationCode] = WebsocketOperationCodes.VoiceStateUpdate,
				[WebsocketOperationKeys.Data] = {
					guild_id = guildId,
					channel_id = channelId,
					self_mute = false,
					self_deaf = false,
				},
			})
			:await()

		repeat
			Task.wait(0.5)
		until self.voiceServerUpdate and self.voiceStateUpdate

		connection:disconnect()

		self.guildId = guildId
		self.channelId = channelId

		self.voiceWebsocket:connectAsync(`wss://{self.voiceServerUpdate.endpoint}/?v=4`):await()
		self.voiceWebsocket
			:sendAsync({
				[WebsocketOperationKeys.OperationCode] = VoiceWebsocketOperationCodes.Identify,
				[WebsocketOperationKeys.Data] = {
					server_id = guildId,
					user_id = self.discordClient.discordUser.id,
					session_id = self.voiceStateUpdate.sessionId,
					token = self.voiceServerUpdate.token,
				},
			})
			:await()

		return true
	end)
end

--[=[
	Resumes a voice connection asynchronously.
	
	@private
	@method resumeAsync
	@param self DiscordVoiceConnection
	@within Network.DiscordVoiceConnection
	@return Vendor.Future
]=]
function DiscordVoiceConnection.Prototype.resumeAsync(self: DiscordVoiceConnection)
	return Future.try(function()
		self.voiceWebsocket:connectAsync(`wss://{self.voiceServerUpdate.endpoint}/?v=4`):await()
		self.voiceWebsocket
			:sendAsync({
				[WebsocketOperationKeys.OperationCode] = VoiceWebsocketOperationCodes.Resume,
				[WebsocketOperationKeys.Data] = {
					server_id = self.guildId,
					session_id = self.voiceStateUpdate.sessionId,
					token = self.voiceServerUpdate.token,
				},
			})
			:await()

		return true
	end)
end

--[=[
	Reconnects to the voice websocket asynchronously.
	
	@private
	@method reconnectAsync
	@param self DiscordVoiceConnection
	@within Network.DiscordVoiceConnection
	@return Vendor.Future
]=]
function DiscordVoiceConnection.Prototype.reconnectAsync(self: DiscordVoiceConnection)
	if self.heartbeatTask then
		Task.cancel(self.heartbeatTask)
	end

	return Future.try(function()
		self.voiceWebsocket:disconnectAsync(tostring(1005)):await()

		Task.wait(math.random())

		self:resumeAsync():await()
	end)
end

--[=[
	Disconnects from the voice websocket asynchronously.
	
	@private
	@method disconnectAsync
	@param self DiscordVoiceConnection
	@within Network.DiscordVoiceConnection
	@return Vendor.Future
]=]
function DiscordVoiceConnection.Prototype.disconnectAsync(self: DiscordVoiceConnection)
	return Future.try(function()
		if self.heartbeatTask then
			Task.cancel(self.heartbeatTask)
		end

		local guildObject = self.discordClient:fetchGuildAsync(self.guildId):await()
		local websocket: DiscordWebsocket.DiscordWebsocket =
			self.discordClient.discordShards[guildObject.shardId].discordWebsocket

		websocket
			:sendAsync({
				[WebsocketOperationKeys.OperationCode] = WebsocketOperationCodes.VoiceStateUpdate,
				[WebsocketOperationKeys.Data] = {
					guild_id = self.guildId,
				},
			})
			:await()

		self.voiceWebsocket:disconnectAsync(tostring(1000)):await()

		DiscordVoiceConnection.Prototype.activeConnections -= 1
	end)
end

--[=[
	Creates a new instance of `DiscordVoiceConnection`.
	
	@private
	@function new
	@param discordClient any -- The Discord client.
	@param id string -- The ID for this connection.
	@within Network.DiscordVoiceConnection
	@return DiscordVoiceConnection
]=]
function DiscordVoiceConnection.Interface.new(discordClient: any, id: string): DiscordVoiceConnection
	--[=[
		@prop voiceWebsocket Network.DiscordWebsocket
		@within Network.DiscordVoiceConnection
	]=]

	--[=[
		@prop voiceUDP Network.VoiceUDP
		@within Network.DiscordVoiceConnection
	]=]

	--[=[
		@prop reporter Vendor.Console
		@within Network.DiscordVoiceConnection
	]=]

	--[=[
		@prop heartbeatTask thread?
		@within Network.DiscordVoiceConnection
	]=]

	--[=[
		@prop resumeSessionId string
		@within Network.DiscordVoiceConnection
	]=]

	--[=[
		@prop heartbeatInterval number
		@within Network.DiscordVoiceConnection
	]=]

	--[=[
		@prop heartbeatAck boolean?
		@within Network.DiscordVoiceConnection
	]=]

	--[=[
		@prop heartbeatPing number?
		@within Network.DiscordVoiceConnection
	]=]

	--[=[
		@prop heartbeatNonce number?
		@within Network.DiscordVoiceConnection
	]=]

	--[=[
		@prop heartbeatClockTime number?
		@within Network.DiscordVoiceConnection
	]=]

	--[=[
		@prop encryptionKey buffer
		@within Network.DiscordVoiceConnection
	]=]

	--[=[
		@prop mediaSessionId string
		@within Network.DiscordVoiceConnection
	]=]

	--[=[
		@prop channelId string
		@within Network.DiscordVoiceConnection
	]=]

	--[=[
		@prop guildId string
		@within Network.DiscordVoiceConnection
	]=]

	--[=[
		@prop voiceServerUpdate { endpoint: string, token: string, guildId: string, }
		@within Network.DiscordVoiceConnection
	]=]

	--[=[
		@prop voiceStateUpdate { sessionId: string, }
		@within Network.DiscordVoiceConnection
	]=]

	--[=[
		@prop onEvent Vendor.Signal
		@within Network.DiscordVoiceConnection
	]=]
	local self = (
		Construct({
			voiceWebsocket = DiscordWebsocket.new(),
			discordClient = discordClient,

			reporter = Console.new(`🖲️  DiscordVoiceConnection {id}`),

			heartbeatTask = nil,
			resumeSessionId = nil,
			heartbeatInterval = nil,

			onEvent = Signal.new(),
		}, DiscordVoiceConnection.Prototype) :: unknown
	) :: DiscordVoiceConnection

	self:observeWebsocketOperations()

	return self
end

export type DiscordVoiceConnection = typeof(DiscordVoiceConnection.Prototype) & {
	voiceWebsocket: DiscordWebsocket.DiscordWebsocket,
	voiceUDP: DiscordUDP.DiscordUDP,
	discordClient: any,

	reporter: Console.Console,

	heartbeatTask: thread?,
	resumeSessionId: string,
	heartbeatInterval: number,

	heartbeatAck: boolean?,
	heartbeatPing: number?,
	heartbeatNonce: number?,
	heartbeatClockTime: number?,

	encryptionKey: buffer,
	mediaSessionId: string,

	channelId: string,
	guildId: string,

	voiceServerUpdate: {
		endpoint: string,
		token: string,
		guildId: string,
	},

	voiceStateUpdate: {
		sessionId: string,
	},

	onEvent: unknown,
}

return DiscordVoiceConnection.Interface
