local WebsocketOperationCodes = require("../../Enums/WebsocketOperationCodes")
local WebsocketOperationKeys = require("../../Enums/WebsocketOperationKeys")

local WebsocketEvents = require("../../Enums/WebsocketEvents")

local Construct = require("../../Utils/Construct")

local Future = require("../../Vendor/Future")
local Console = require("../../Vendor/Console")
local Signal = require("../../Vendor/Signal")

local DiscordWebsocket = require("DiscordWebsocket")

local Process = require("@lune/process")
local Task = require("@lune/task")

local LIBRARY_IDENTIFIER = "DiscordLuau"

local DiscordShard = {}

DiscordShard.Type = "DiscordShard"

DiscordShard.Interface = {}
DiscordShard.Prototype = {}

function DiscordShard.Prototype.observeWebsocketEvents(self: DiscordShard)
	self.OnEvent:connect(function(eventName, data)
		if eventName == WebsocketEvents.Ready then
			local websocketVersion = self.DiscordClient.DiscordGateway:getApiVersion()

			self.Reporter:log(`DiscordShard is active - id: "{data.session_id}"`)

			self.ResumeSessionId = data.session_id
			self.ResumeGatewayUrl = `{data.resume_gateway_url}/?v={websocketVersion}`
		end
	end)
end

function DiscordShard.Prototype.observeWebsocketOperations(self: DiscordShard)
	self.DiscordWebsocket.OnOperationRecv:connect(function(operationCode, operationData, eventName, sequence)
		if operationCode == WebsocketOperationCodes.Dispatch then
			self.DispatchSequence = sequence

			self.OnEvent:fire(eventName, operationData)
		elseif operationCode == WebsocketOperationCodes.Hello then
			Task.wait(math.random())

			self.HeartbeatInterval = operationData.heartbeat_interval
			self:heartbeatAsync(true):after(function()
				self:heartbeatIn(math.random(self.HeartbeatInterval / 2, self.HeartbeatInterval))
			end)
		elseif operationCode == WebsocketOperationCodes.Heartbeat then
			self.Reporter:log(`Discord Websocket requested heartbeat, sending heartbeat!`)

			self:heartbeatAsync(true)
		elseif operationCode == WebsocketOperationCodes.HeartbeatACK then
			self.HeartbeatAck = true
			self.HeartbeatPing = os.clock() - self.HeartbeatClockTime

			self.Reporter:debug(`HeartbeatACK - Ping: {self.HeartbeatPing}`)

			if not self.Identified then
				self.Identified = true

				xpcall(function()
					self:identifyAsync():await()
				end, function(exception)
					self.Reporter:warn(`:identifyAsync call failed: '{exception}'`)

					self.Identified = nil
				end)
			end
		elseif operationCode == WebsocketOperationCodes.Reconnect then
			self.Reporter:log(`Discord Websocket requested reconnect, attempting to reconnect!`)

			self:reconnectAsync()
		elseif operationCode == WebsocketOperationCodes.InvalidSession then
			self.Reporter:Warn(`Discord Websocket session invalid!`)

			if operationData == true then
				self.Reporter:log(`Attempting to reconnect from Invalid Session!`)
	
				self:reconnectAsync()
			else
				error(`Discord session was invalidated, please ensure that the bot's permissions & token is correct!`)
			end
		end
	end)
end

function DiscordShard.Prototype.heartbeatAsync(self: DiscordShard, ignoreHeartbeatAck: boolean?)
	return Future.try(function()
		if not ignoreHeartbeatAck then
			if not self.HeartbeatAck then
				self.Reporter:Warn(`Discord Websocket state has become zombified, attempting to reconnect!`)

				self:reconnectAsync():await()
			end

			self.HeartbeatAck = nil
		end

		self.HeartbeatClockTime = os.clock()

		self.DiscordWebsocket:sendAsync({
			[WebsocketOperationKeys.OperationCode] = WebsocketOperationCodes.Heartbeat,
			[WebsocketOperationKeys.Data] = self.DispatchSequence or false,
		}):await()
	end)
end

function DiscordShard.Prototype.heartbeatIn(self: DiscordShard, milliseconds: number)
	if self.HeartbeatTask then
		Task.cancel(self.HeartbeatTask)
	end

	self.HeartbeatTask = Task.delay(milliseconds / 1000, function()
		self.HeartbeatTask = nil

		self:heartbeatAsync():await()
		self:heartbeatIn(milliseconds)
	end)
end

function DiscordShard.Prototype.identifyAsync(self: DiscordShard)
	return Future.try(function()
		self.DiscordWebsocket:sendAsync({
			[WebsocketOperationKeys.OperationCode] = WebsocketOperationCodes.Identify,
			[WebsocketOperationKeys.Data] = {
				["token"] = self.DiscordClient.DiscordSettings.DiscordToken,
				["intents"] = self.DiscordClient.DiscordSettings.DiscordIntents.Intents,
				["properties"] = {
					["os"] = Process.os,
					["browser"] = LIBRARY_IDENTIFIER,
					["device"] = LIBRARY_IDENTIFIER,
				},
				["compress"] = true,
				["large_threshold"] = 250,
				["shard"] = {
					self.ShardId,
					self.DiscordClient.ShardCount
				},
			},
		}):await()
	end)
end

function DiscordShard.Prototype.connectAsync(self: DiscordShard, ...)
	return self.DiscordWebsocket:connectAsync(...)
end

function DiscordShard.Prototype.resumeAsync(self: DiscordShard)
	return Future.try(function()
		self.DiscordWebsocket:connectAsync(self.ResumeGatewayUrl):await()
		self.DiscordWebsocket:SendAsync({
			[WebsocketOperationKeys.OperationCode] = WebsocketOperationCodes.Resume,
			[WebsocketOperationKeys.Data] = {
				token = self.DiscordClient.DiscordToken,
				session_id = self.ResumeSessionId,
				seq = self.DispatchSequence
			},
		}):await()
	end)
end

function DiscordShard.Prototype.reconnectAsync(self: DiscordShard)
	if self.HeartbeatTask then
		Task.cancel(self.HeartbeatTask)
	end

	return Future.try(function()
		self.DiscordWebsocket:disconnectAsync(1005):await()

		Task.wait(math.random())
	
		self:resumeAsync():await()
	end)
end

function DiscordShard.Interface.new(discordClient: any, shardId: number)
	local self = Construct({
		DiscordWebsocket = DiscordWebsocket.new(discordClient),
		DiscordClient = discordClient,

		Reporter = Console.new(`DiscordShard_{shardId}`),

		OnEvent = Signal.new(),

		ShardId = shardId
	}, DiscordShard.Prototype)

	self:observeWebsocketEvents()
	self:observeWebsocketOperations()

	return self
end

export type DiscordShard = typeof(DiscordShard.Interface.new(nil, 0))

return DiscordShard.Interface