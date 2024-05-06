local WebsocketOperationCodes = require("../../Enums/WebsocketOperationCodes")
local WebsocketOperationKeys = require("../../Enums/WebsocketOperationKeys")
local WebsocketCloseCodes = require("../../Enums/WebsocketCloseCodes")

local WebsocketEvents = require("../../Enums/WebsocketEvents")

local Construct = require("../../Utils/Construct")

local Future = require("../../Vendor/Future")
local Console = require("../../Vendor/Console")
local Signal = require("../../Vendor/Signal")

local DiscordWebsocket = require("DiscordWebsocket")

local Process = require("../../Std/Process")
local Task = require("../../Std/Task")

local LIBRARY_IDENTIFIER = "DiscordLuau"

--[=[
	@class Internal.DiscordShard

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local DiscordShard = {}

DiscordShard.Interface = {}
DiscordShard.Prototype = {}

DiscordShard.Prototype.type = "DiscordShard"

function DiscordShard.Prototype.observeWebsocketErrors(self: DiscordShard)
	table.insert(self.activeConnections, self.discordWebsocket.onSocketDead:connect(function(closeCode)
		if closeCode == WebsocketCloseCodes.UnknownError then
			self:reconnectAsync()
		elseif closeCode == WebsocketCloseCodes.UnknownOperation then
			self:reconnectAsync()
		elseif closeCode == WebsocketCloseCodes.DecodeError then
			self:reconnectAsync()
		elseif closeCode == WebsocketCloseCodes.NotAuthenticated then
			self.reporter:error(`Something has gone terribly wrong with Discord-Luau.. please create an issue! [{closeCode}]`)
		elseif closeCode == WebsocketCloseCodes.AuthenticationFailed then
			self.reporter:warn(`Failed to authenticate with the Discord API, is your token correct?`)
		elseif closeCode == WebsocketCloseCodes.AlreadyAuthenticated then
			self:reconnectAsync()
		elseif closeCode == WebsocketCloseCodes.InvalidSequence then
			self:reconnectAsync()
		elseif closeCode == WebsocketCloseCodes.RateLimited then
			self:reconnectAsync()
		elseif closeCode == WebsocketCloseCodes.SessionTimedOut then
			self:reconnectAsync()
		elseif closeCode == WebsocketCloseCodes.InvalidShard then
			self.reporter:error(`Something has gone terribly wrong with Discord-Luau.. please create an issue! [{closeCode}]`)
		elseif closeCode == WebsocketCloseCodes.InvalidAPIVersion then
			self.reporter:error(`Something has gone terribly wrong with Discord-Luau.. please create an issue! [{closeCode}]`)
		elseif closeCode == WebsocketCloseCodes.InvalidIntents then
			self.reporter:error(`Something has gone terribly wrong with Discord-Luau.. please create an issue! [{closeCode}]`)
		elseif closeCode == WebsocketCloseCodes.DisallowedIntents then
			self.reporter:warn(`Discord Bot intents are invalid, are you sure the bot has the chosen intents enabled?`)
		end
	end))
end

function DiscordShard.Prototype.observeWebsocketEvents(self: DiscordShard)
	table.insert(self.activeConnections, self.onEvent:connect(function(eventName, data)
		if eventName == WebsocketEvents.Ready then
			local websocketVersion = self.discordClient.discordGateway:getApiVersion()

			self.reporter:log(`DiscordShard is active - id: "{data.sessionId}"`)

			self.resumeSessionId = data.sessionId
			self.resumeGatewayUrl = `{data.resumeGatewayUrl}/?v={websocketVersion}`
		end
	end))
end

function DiscordShard.Prototype.observeWebsocketOperations(self: DiscordShard)
	table.insert(self.activeConnections, self.discordWebsocket.onOperationRecv:connect(function(operationCode, operationData, eventName, sequence)
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
		elseif operationCode == WebsocketOperationCodes.heartbeatAck then
			self.heartbeatAck = true
			self.HeartbeatPing = os.clock() - self.HeartbeatClockTime

			self.reporter:debug(`heartbeatAck - Ping: {self.HeartbeatPing}`)

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
			self.reporter:warn(`Discord Websocket session invalid!`)

			if operationData == true then
				self.reporter:log(`Attempting to reconnect from Invalid Session!`)
	
				self:reconnectAsync()
			else
				self.reporter:warn(`Unrecoverable InvalidSession, attempting to destroy and recreate websocket.`)

				self.discordWebsocket:disconnectAsync(1005):await()

				Task.wait(5)

				self:initiateWebsocket()
				self:connectAsync(self.websocketUrl)
			end
		end
	end))
end

function DiscordShard.Prototype.initiateWebsocket(self: DiscordShard)
	self.discordWebsocket = DiscordWebsocket.new(self.websocketUrl)

	for _, connection in self.activeConnections do
		connection:disconnect()
	end

	self:observeWebsocketEvents()
	self:observeWebsocketErrors()
	self:observeWebsocketOperations()
end

function DiscordShard.Prototype.heartbeatAsync(self: DiscordShard, ignoreheartbeatAck: boolean?)
	return Future.try(function()
		if not ignoreheartbeatAck then
			if not self.heartbeatAck then
				self.reporter:warn(`Discord Websocket state has become zombified, attempting to reconnect!`)

				self:reconnectAsync():await()
			end

			self.heartbeatAck = nil
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

function DiscordShard.Prototype.connectAsync(self: DiscordShard, websocketUrl: string)
	self.websocketUrl = websocketUrl

	return self.discordWebsocket:connectAsync(websocketUrl)
end

function DiscordShard.Prototype.resumeAsync(self: DiscordShard)
	return Future.try(function()
		self.discordWebsocket:connectAsync(self.resumeGatewayUrl):await()
		self.discordWebsocket:sendAsync({
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

function DiscordShard.Interface.new(discordClient: any, shardId: number): DiscordShard
	local self = Construct({
		discordClient = discordClient,
		discordWebsocket = nil,
		activeConnections = {},

		websocketUrl = "",

		reporter = Console.new(`🖲️  DiscordShard {shardId}`),

		heartbeatTask = nil,
		resumeSessionId = nil,
		dispatchSequence = nil,
		heartbeatInterval = nil,

		onEvent = Signal.new(),

		shardId = shardId
	}, DiscordShard.Prototype)

	self:initiateWebsocket()

	return self
end

export type DiscordShard = typeof(DiscordShard.Prototype) & {
	discordWebsocket: DiscordWebsocket.DiscordWebsocket,
	discordClient: unknown,

	websocketUrl: string,

	reporter: unknown,

	heartbeatTask: thread?,
	resumeSessionId: string,
	dispatchSequence: number,
	heartbeatInterval: number,

	onEvent: unknown,

	shardId: number
}

return DiscordShard.Interface