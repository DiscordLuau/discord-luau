local VoiceWebsocketOperationCodes = require("../../Enums/VoiceWebsocketOperationCodes")
local WebsocketOperationCodes = require("../../Enums/WebsocketOperationCodes")
local WebsocketOperationKeys = require("../../Enums/WebsocketOperationKeys")

local WebsocketEvents = require("../../Enums/WebsocketEvents")

local Construct = require("../../Utils/Construct")

local Future = require("../../Vendor/Future")
local Console = require("../../Vendor/Console")
local Signal = require("../../Vendor/Signal")

local DiscordWebsocket = require("DiscordWebsocket")
local DiscordUDP = require("DiscordUDP")

local Task = require("@lune/task")
local Net = require("@lune/net")

--[=[
	@class Internal.DiscordVoiceConnection

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local DiscordVoiceConnection = {}

DiscordVoiceConnection.Interface = {}
DiscordVoiceConnection.Prototype = {}

DiscordVoiceConnection.Prototype.type = "DiscordVoiceConnection"

function DiscordVoiceConnection.Prototype.observeWebsocketOperations(self: DiscordVoiceConnection)
	self.voiceWebsocket.onOperationRecv:connect(function(operationCode, operationData)
		if operationCode == VoiceWebsocketOperationCodes.Hello then
			Task.wait(math.random())

			self.heartbeatInterval = operationData.heartbeatInterval
			self:heartbeatAsync(true):after(function()
				self:heartbeatIn(math.random(self.heartbeatInterval / 2, self.heartbeatInterval))
			end)
		elseif operationCode == VoiceWebsocketOperationCodes.HeartbeatACK then
			self.heartbeatAck = true
			self.heartbeatPing = os.clock() - self.heartbeatClockTime

			self.reporter:debug(`HeartbeatACK - Ping: {self.heartbeatPing}`)
		elseif operationCode == VoiceWebsocketOperationCodes.Ready then
			local udpSocket = (Net :: any).udpSocket("0.0.0.0:6826")

			local data = string.pack(`>I2I2I4c64I2`, 1, 70, operationData.ssrc, operationData.ip, operationData.port)

			udpSocket:connect(`{operationData.ip}:{operationData.port}`)
			udpSocket:send(data)

			local responseBuffer = udpSocket:next()
			local responseData = { string.unpack(">I2I2I4c64I2", buffer.tostring(responseBuffer)) }
			
			(Net :: any).udpSocketClose(udpSocket)

			local publicAddress = responseData[4]
			local publicPort = responseData[5]

			self.voiceUDP = DiscordUDP.new(`0.0.0.0:6827`)
			self.voiceUDP:connectAsync(`{operationData.ip}:{operationData.port}`)

			self.voiceWebsocket:sendAsync({
				[WebsocketOperationKeys.OperationCode] = VoiceWebsocketOperationCodes.SelectProtocol,
				[WebsocketOperationKeys.Data] = {
					protocol = "udp",
					data = {
						address = publicAddress,
						port = 6827,
						mode = "xsalsa20_poly1305"
					}
				}
			}):await()
		elseif operationCode == VoiceWebsocketOperationCodes.SessionDescription then
			local encryptionKey = buffer.create(64)

			for index = 1, 32 do
				buffer.writei16(encryptionKey, index, operationData.secretKey[tostring(index)])
			end

			print("encryption key: ", buffer.tostring(encryptionKey))

			print(operationData)
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
		self.heartbeatNonce = math.random(1_000_000_000) -- fixme: validate nonce on Heartbeat ACK

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
		local connections = {}

		for shardId = 1, self.discordClient.shardCount do
			table.insert(connections, self.discordClient.discordShards[shardId].onEvent:connect(function(eventName, data)
				if eventName == WebsocketEvents.VoiceServerUpdate then
					if data.guildId == guildId then
						self.voiceServerUpdate = data
					end
				elseif eventName == WebsocketEvents.VoiceStateUpdate then
					if data.userId == self.discordClient.discordUser.id then
						self.voiceStateUpdate = data
					end
				end
			end))

			self.discordClient.discordShards[shardId].discordWebsocket:sendAsync(
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
		end

		for _, connection in connections do
			connection:disconnect()
		end

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
		self.voiceWebsocket:disconnectAsync(1005):await()

		Task.wait(math.random())
	
		self:resumeAsync():await()
	end)
end

function DiscordVoiceConnection.Prototype.disconnectAsync(self: DiscordVoiceConnection)
	return Future.try(function()
		if self.heartbeatTask then
			Task.cancel(self.heartbeatTask)
		end

		self.voiceWebsocket:disconnectAsync(1000):await()
	end)
end

function DiscordVoiceConnection.Interface.new(discordClient: any, shardId: number): DiscordVoiceConnection
	local self = Construct({
		voiceWebsocket = DiscordWebsocket.new(),
		-- voiceUDP = DiscordUDP.new(),
		discordClient = discordClient,

		reporter = Console.new(`🖲️  DiscordVoiceConnection {shardId}`),

		heartbeatTask = nil,
		resumeSessionId = nil,
		heartbeatInterval = nil,

		onEvent = Signal.new(),

		shardId = shardId
	}, DiscordVoiceConnection.Prototype)

	self:observeWebsocketOperations()

	return self
end

export type DiscordVoiceConnection = typeof(DiscordVoiceConnection.Prototype) & {
	voiceWebsocket: DiscordWebsocket.DiscordWebsocket,
	voiceUDP: DiscordUDP.DiscordUDP,
	discordClient: unknown,

	reporter: unknown,

	heartbeatTask: thread?,
	resumeSessionId: string,
	heartbeatInterval: number,

	voiceServerUpdate: {
		endpoint: string,
		token: string,
		guildId: string,
	},

	voiceStateUpdate: {
		sessionId: string,

		-- there are other props here i'm too lazy to add lol.
	},

	onEvent: unknown,

	shardId: number
}

return DiscordVoiceConnection.Interface