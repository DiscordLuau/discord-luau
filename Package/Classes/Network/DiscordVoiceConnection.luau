local VoiceWebsocketOperationCodes = require("../../Enums/VoiceWebsocketOperationCodes")
local VoiceWebsocketCloseCodes = require("../../Enums/VoiceWebsocketCloseCodes")
local WebsocketOperationCodes = require("../../Enums/WebsocketOperationCodes")
local WebsocketOperationKeys = require("../../Enums/WebsocketOperationKeys")

local WebsocketEvents = require("../../Enums/WebsocketEvents")

local Construct = require("../../Utils/Construct")

local Future = require("../../Vendor/Future")
local Console = require("../../Vendor/Console")
local Signal = require("../../Vendor/Signal")

local DiscordWebsocket = require("DiscordWebsocket")
local DiscordUDP = require("DiscordUDP")

local Task = require("../../Std/Task")

local BASE_VOICE_CONNECTION_PORT = 1050

--[=[
	@class Network.DiscordVoiceConnection

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local DiscordVoiceConnection = {}

DiscordVoiceConnection.Internal = {}
DiscordVoiceConnection.Interface = {}
DiscordVoiceConnection.Prototype = {}

DiscordVoiceConnection.Prototype.type = "DiscordVoiceConnection"

DiscordVoiceConnection.Internal.publicAddress = nil
DiscordVoiceConnection.Internal.publicPort = nil

DiscordVoiceConnection.Internal.activeConnections = 0

function DiscordVoiceConnection.Prototype.observeWebsocketErrors(self: DiscordVoiceConnection)
	self.voiceWebsocket.onSocketDead:connect(function(closeCode)
		if closeCode == VoiceWebsocketCloseCodes.UnknownError then
			self:reconnectAsync()
		elseif closeCode == VoiceWebsocketCloseCodes.UnknownOperation then
			self:reconnectAsync()
		elseif closeCode == VoiceWebsocketCloseCodes.DecodeError then
			self:reconnectAsync()
		elseif closeCode == VoiceWebsocketCloseCodes.NotAuthenticated then
			self.reporter:error(`Something has gone terribly wrong with Discord-Luau.. please create an issue! [{closeCode}]`)
		elseif closeCode == VoiceWebsocketCloseCodes.AuthenticationFailed then
			self.reporter:warn(`Failed to authenticate with the Discord Voice Gateway, is your token correct?`)
		elseif closeCode == VoiceWebsocketCloseCodes.AlreadyAuthenticated then
			self:reconnectAsync()
		elseif closeCode == VoiceWebsocketCloseCodes.SessionTimedOut then
			self:reconnectAsync()
		elseif closeCode == VoiceWebsocketCloseCodes.ServerNotFound then
			self.reporter:error(`Voice Websocket unable to find server; '{self.guildId}'`)
		elseif closeCode == VoiceWebsocketCloseCodes.UnknownProtocol then
			self.reporter:error(`Something has gone terribly wrong with Discord-Luau.. please create an issue! [{closeCode}]`)
		elseif closeCode == VoiceWebsocketCloseCodes.Disconnected then
			self.reporter:debug(`Disconnected from Voice websocket`)
		elseif closeCode == VoiceWebsocketCloseCodes.VoiceServerCrashed then
			self:reconnectAsync()
		elseif closeCode == VoiceWebsocketCloseCodes.UnknownEncryptionMode then
			self.reporter:error(`Something has gone terribly wrong with Discord-Luau.. please create an issue! [{closeCode}]`)
		end
	end)
end

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
				self.reporter:warn(`HeartbeatACK - nonce recieved was incorrect`)
			end

			self.reporter:debug(`HeartbeatACK - Ping: {self.heartbeatPing}`)
		elseif operationCode == VoiceWebsocketOperationCodes.Ready then
			DiscordVoiceConnection.Internal.activeConnections += 1

			local thread = coroutine.running()

			self.voiceUDP = (DiscordUDP.new(
				`0.0.0.0:{BASE_VOICE_CONNECTION_PORT + DiscordVoiceConnection.Internal.activeConnections}`
			) :: unknown) :: DiscordUDP.DiscordUDP
			
			self.voiceUDP.onMessageRecv:once(function(packetData: string)
				local responseData = { string.unpack(">I2I2I4c64I2", packetData) }

				coroutine.resume(thread, responseData[4])
			end)
			
			self.voiceUDP:connectAsync(`{operationData.ip}:{operationData.port}`):await()
			self.voiceUDP:sendAsync(
				string.pack(`>I2I2I4c64I2`, 1, 70, operationData.ssrc, operationData.ip, operationData.port)
			)

			local publicIp = coroutine.yield()

			self.voiceWebsocket:sendAsync({
				[WebsocketOperationKeys.OperationCode] = VoiceWebsocketOperationCodes.SelectProtocol,
				[WebsocketOperationKeys.Data] = {
					protocol = "udp",
					data = {
						address = publicIp,
						port = BASE_VOICE_CONNECTION_PORT + DiscordVoiceConnection.Internal.activeConnections,
						mode = "xsalsa20_poly1305"
					}
				}
			}):await()
		elseif operationCode == VoiceWebsocketOperationCodes.SessionDescription then
			self.encryptionKey = buffer.create(64)
			self.mediaSessionId = operationData.mediaSessionId

			for index = 1, 32 do
				buffer.writei16(self.encryptionKey, index, operationData.secretKey[tostring(index)])
			end
		end
	end)
end

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

		self.voiceWebsocket:sendAsync({
			[WebsocketOperationKeys.OperationCode] = VoiceWebsocketOperationCodes.Heartbeat,
			[WebsocketOperationKeys.Data] = self.heartbeatNonce,
		}):await()
	end)
end

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

function DiscordVoiceConnection.Prototype.identifyAsync(self: DiscordVoiceConnection)
	return Future.try(function()
		
	end)
end

function DiscordVoiceConnection.Prototype.connectAsync(self: DiscordVoiceConnection, guildId: string, channelId: string)
	return Future.try(function()
		local guildObject = self.discordClient:fetchGuildAsync(guildId):await()
		local websocket: DiscordWebsocket.DiscordWebsocket = self.discordClient.discordShards[guildObject.shardId].discordWebsocket
		local connection

		connection = self.discordClient.discordShards[guildObject.shardId].onEvent:connect(function(eventName, data: {[any]: any})
			if eventName == WebsocketEvents.VoiceServerUpdate then
				if data.guildId == guildId then
					self.voiceServerUpdate = data
				end
			elseif eventName == WebsocketEvents.VoiceStateUpdate then
				if data.userId == self.discordClient.discordUser.id then
					self.voiceStateUpdate = data
				end
			end
		end)

		websocket:sendAsync(
			{
				[WebsocketOperationKeys.OperationCode] = WebsocketOperationCodes.VoiceStateUpdate,
				[WebsocketOperationKeys.Data] = {
					guild_id = guildId,
					channel_id = channelId,
					self_mute = false,
					self_deaf = false,
				},
			}
		):await()

		repeat
			Task.wait(0.5)
		until self.voiceServerUpdate and self.voiceStateUpdate

		connection:disconnect()

		self.guildId = guildId
		self.channelId = channelId

		self.voiceWebsocket:connectAsync(`wss://{self.voiceServerUpdate.endpoint}/?v=4`):await()
		self.voiceWebsocket:sendAsync({
			[WebsocketOperationKeys.OperationCode] = VoiceWebsocketOperationCodes.Identify,
			[WebsocketOperationKeys.Data] = {
				server_id = guildId,
				user_id = self.discordClient.discordUser.id,
				session_id = self.voiceStateUpdate.sessionId,
				token = self.voiceServerUpdate.token
			}
		}):await()

		return true
	end)
end

function DiscordVoiceConnection.Prototype.resumeAsync(self: DiscordVoiceConnection)
	return Future.try(function()
		self.voiceWebsocket:connectAsync(`wss://{self.voiceServerUpdate.endpoint}/?v=4`):await()
		self.voiceWebsocket:sendAsync({
			[WebsocketOperationKeys.OperationCode] = VoiceWebsocketOperationCodes.Resume,
			[WebsocketOperationKeys.Data] = {
				server_id = self.guildId,
				session_id = self.voiceStateUpdate.sessionId,
				token = self.voiceServerUpdate.token
			}
		}):await()

		return true
	end)
end

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

function DiscordVoiceConnection.Prototype.disconnectAsync(self: DiscordVoiceConnection)
	return Future.try(function()
		if self.heartbeatTask then
			Task.cancel(self.heartbeatTask)
		end

		local guildObject = self.discordClient:fetchGuildAsync(self.guildId):await()
		local websocket: DiscordWebsocket.DiscordWebsocket = self.discordClient.discordShards[guildObject.shardId].discordWebsocket

		websocket:sendAsync(
			{
				[WebsocketOperationKeys.OperationCode] = WebsocketOperationCodes.VoiceStateUpdate,
				[WebsocketOperationKeys.Data] = {
					guild_id = self.guildId
				},
			}
		):await()

		self.voiceWebsocket:disconnectAsync(tostring(1000)):await()

		DiscordVoiceConnection.Internal.activeConnections -= 1
	end)
end

function DiscordVoiceConnection.Interface.new(discordClient: any, id: string): DiscordVoiceConnection
	local self = Construct({
		voiceWebsocket = DiscordWebsocket.new(),
		discordClient = discordClient,

		reporter = Console.new(`🖲️  DiscordVoiceConnection {id}`),

		heartbeatTask = nil,
		resumeSessionId = nil,
		heartbeatInterval = nil,

		onEvent = Signal.new()
	}, DiscordVoiceConnection.Prototype) :: any

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