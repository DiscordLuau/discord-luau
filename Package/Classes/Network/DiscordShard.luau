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

--[=[
	@class Internal.DiscordShard

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local DiscordShard = {}

DiscordShard.Interface = {}
DiscordShard.Prototype = {}

DiscordShard.Prototype.type = "DiscordShard"

function DiscordShard.Prototype.observeWebsocketEvents(self: DiscordShard)
	self.onEvent:connect(function(eventName, data)
		if eventName == WebsocketEvents.Ready then
			local websocketVersion = self.discordClient.discordGateway:getApiVersion()

			self.reporter:log(`DiscordShard is active - id: "{data.sessionId}"`)

			self.resumeSessionId = data.session_id
			self.ResumeGatewayUrl = `{data.resume_gateway_url}/?v={websocketVersion}`
		end
	end)
end

function DiscordShard.Prototype.observeWebsocketOperations(self: DiscordShard)
	self.discordWebsocket.onOperationRecv:connect(function(operationCode, operationData, eventName, sequence)
		if operationCode == WebsocketOperationCodes.Dispatch then
			self.dispatchSequence = sequence

			self.onEvent:fire(eventName, operationData)
		elseif operationCode == WebsocketOperationCodes.Hello then
			Task.wait(math.random())

			self.heartbeatInterval = operationData.heartbeatInterval
			self:heartbeatAsync(true):after(function()
				self:heartbeatIn(math.random(self.heartbeatInterval / 2, self.heartbeatInterval))
			end)
		elseif operationCode == WebsocketOperationCodes.Heartbeat then
			self.reporter:log(`Discord Websocket requested heartbeat, sending heartbeat!`)

			self:heartbeatAsync(true)
		elseif operationCode == WebsocketOperationCodes.HeartbeatACK then
			self.HeartbeatAck = true
			self.HeartbeatPing = os.clock() - self.HeartbeatClockTime

			self.reporter:debug(`HeartbeatACK - Ping: {self.HeartbeatPing}`)

			if not self.Identified then
				self.Identified = true

				xpcall(function()
					self:identifyAsync():await()
				end, function(exception)
					self.reporter:warn(`:identifyAsync call failed: '{exception}'`)

					self.Identified = nil
				end)
			end
		elseif operationCode == WebsocketOperationCodes.Reconnect then
			self.reporter:log(`Discord Websocket requested reconnect, attempting to reconnect!`)

			self:reconnectAsync()
		elseif operationCode == WebsocketOperationCodes.InvalidSession then
			self.reporter:Warn(`Discord Websocket session invalid!`)

			if operationData == true then
				self.reporter:log(`Attempting to reconnect from Invalid Session!`)
	
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
				self.reporter:Warn(`Discord Websocket state has become zombified, attempting to reconnect!`)

				self:reconnectAsync():await()
			end

			self.HeartbeatAck = nil
		end

		self.HeartbeatClockTime = os.clock()

		self.discordWebsocket:sendAsync({
			[WebsocketOperationKeys.OperationCode] = WebsocketOperationCodes.Heartbeat,
			[WebsocketOperationKeys.Data] = self.dispatchSequence or false,
		}):await()
	end)
end

function DiscordShard.Prototype.heartbeatIn(self: DiscordShard, milliseconds: number)
	if self.heartbeatTask then
		Task.cancel(self.heartbeatTask)
	end

	self.heartbeatTask = Task.delay(milliseconds / 1000, function()
		self.heartbeatTask = nil

		self:heartbeatAsync():await()
		self:heartbeatIn(milliseconds)
	end)
end

function DiscordShard.Prototype.identifyAsync(self: DiscordShard)
	return Future.try(function()
		self.discordWebsocket:sendAsync({
			[WebsocketOperationKeys.OperationCode] = WebsocketOperationCodes.Identify,
			[WebsocketOperationKeys.Data] = {
				["token"] = self.discordClient.discordSettings.discordToken,
				["intents"] = self.discordClient.discordSettings.discordIntents.intents,
				["properties"] = {
					["os"] = Process.os,
					["browser"] = LIBRARY_IDENTIFIER,
					["device"] = LIBRARY_IDENTIFIER,
				},
				["compress"] = true,
				["large_threshold"] = 250,
				["shard"] = {
					self.shardId,
					self.discordClient.shardCount
				},
			},
		}):await()
	end)
end

function DiscordShard.Prototype.connectAsync(self: DiscordShard, ...)
	return self.discordWebsocket:connectAsync(...)
end

function DiscordShard.Prototype.resumeAsync(self: DiscordShard)
	return Future.try(function()
		self.discordWebsocket:connectAsync(self.ResumeGatewayUrl):await()
		self.discordWebsocket:SendAsync({
			[WebsocketOperationKeys.OperationCode] = WebsocketOperationCodes.Resume,
			[WebsocketOperationKeys.Data] = {
				token = self.discordClient.discordSettings.discordToken,
				session_id = self.resumeSessionId,
				seq = self.dispatchSequence
			},
		}):await()
	end)
end

function DiscordShard.Prototype.reconnectAsync(self: DiscordShard)
	if self.heartbeatTask then
		Task.cancel(self.heartbeatTask)
	end

	return Future.try(function()
		self.discordWebsocket:disconnectAsync(1005):await()

		Task.wait(math.random())
	
		self:resumeAsync():await()
	end)
end

function DiscordShard.Interface.new(discordClient: any, shardId: number)
	local self = Construct({
		discordWebsocket = DiscordWebsocket.new(),
		discordClient = discordClient,

		reporter = Console.new(`🖲️  DiscordShard {shardId}`),

		heartbeatTask = nil,
		resumeSessionId = nil,
		dispatchSequence = nil,
		heartbeatInterval = nil,

		onEvent = Signal.new(),

		shardId = shardId
	}, DiscordShard.Prototype)

	self:observeWebsocketEvents()
	self:observeWebsocketOperations()

	return self
end

export type DiscordShard = typeof(DiscordShard.Interface.new(nil, 0))

return DiscordShard.Interface