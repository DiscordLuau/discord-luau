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
	@class Network.DiscordShard

	DiscordShard is an internal class responsible for managing the connection and communication with a specific shard of the Discord WebSocket. This class handles events, errors, and operations specific to a shard.

	:::caution
	This class is internal and should not be used directly by developers.
	:::
]=]
local DiscordShard = {}

DiscordShard.Interface = {}
DiscordShard.Prototype = {}

DiscordShard.Prototype.type = "DiscordShard"

--[=[
	Observes and handles WebSocket errors.
	
	@private
	@method observeWebsocketErrors
	@within Network.DiscordShard
]=]
function DiscordShard.Prototype.observeWebsocketErrors(self: DiscordShard)
	table.insert(
		self.activeConnections,
		self.discordWebsocket.onSocketDead:connect(function(closeCode)
			if closeCode == WebsocketCloseCodes.UnknownError then
				self:reconnectAsync()
			elseif closeCode == WebsocketCloseCodes.UnknownOperation then
				self:reconnectAsync()
			elseif closeCode == WebsocketCloseCodes.DecodeError then
				self:reconnectAsync()
			elseif closeCode == WebsocketCloseCodes.NotAuthenticated then
				self.reporter:error(
					`Something has gone terribly wrong with Discord-Luau.. please create an issue! [{closeCode}]`
				)
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
				self.reporter:error(
					`Something has gone terribly wrong with Discord-Luau.. please create an issue! [{closeCode}]`
				)
			elseif closeCode == WebsocketCloseCodes.InvalidAPIVersion then
				self.reporter:error(
					`Something has gone terribly wrong with Discord-Luau.. please create an issue! [{closeCode}]`
				)
			elseif closeCode == WebsocketCloseCodes.InvalidIntents then
				self.reporter:error(
					`Something has gone terribly wrong with Discord-Luau.. please create an issue! [{closeCode}]`
				)
			elseif closeCode == WebsocketCloseCodes.DisallowedIntents then
				self.reporter:warn(
					`Discord Bot intents are invalid, are you sure the bot has the chosen intents enabled?`
				)
			end
		end)
	)
end

--[=[
	Observes and handles WebSocket events.
	
	@private
	@method observeWebsocketEvents
	@within Network.DiscordShard
]=]
function DiscordShard.Prototype.observeWebsocketEvents(self: DiscordShard)
	table.insert(
		self.activeConnections,
		self.onEvent:connect(function(eventName, data)
			if eventName == WebsocketEvents.Ready then
				local websocketVersion = self.discordClient.discordGateway:getApiVersion()

				self.reporter:log(`DiscordShard is active - id: "{data.sessionId}"`)

				self.resumeSessionId = data.sessionId
				self.resumeGatewayUrl = `{data.resumeGatewayUrl}/?v={websocketVersion}`
			end
		end)
	)
end

--[=[
	Observes and handles WebSocket operations.
	
	@private
	@method observeWebsocketOperations
	@within Network.DiscordShard
]=]
function DiscordShard.Prototype.observeWebsocketOperations(self: DiscordShard)
	table.insert(
		self.activeConnections,
		self.discordWebsocket.onOperationRecv:connect(function(operationCode, operationData, eventName, sequence)
			if operationCode == WebsocketOperationCodes.Dispatch then
				self.dispatchSequence = sequence :: number

				self.onEvent:fire(eventName :: string, operationData)
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
				self.heartbeatAck = true
				self.heartbeatPing = os.clock() - self.heartbeatClockTime :: number

				self.reporter:debug(`HeartbeatACK - Ping: {self.heartbeatPing}`)

				if not self.identified then
					self.identified = true

					xpcall(function()
						self:identifyAsync():await()
					end, function(exception)
						self.reporter:warn(`:identifyAsync call failed: '{exception}'`)

						self.identified = nil
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

					self.discordWebsocket:disconnectAsync(tostring(1005)):await()

					Task.wait(5)

					self:initiateWebsocket()
					self:connectAsync(self.websocketUrl)
				end
			end
		end)
	)
end

--[=[
	Initiates the WebSocket connection.
	
	@private
	@method initiateWebsocket
	@within Network.DiscordShard
]=]
function DiscordShard.Prototype.initiateWebsocket(self: DiscordShard)
	self.discordWebsocket = DiscordWebsocket.new()

	for _, connection in self.activeConnections do
		connection:disconnect()
	end

	self:observeWebsocketEvents()
	self:observeWebsocketErrors()
	self:observeWebsocketOperations()
end

--[=[
	Sends a heartbeat to the Discord WebSocket.
	
	@private
	@method heartbeatAsync
	@within Network.DiscordShard
	@param ignoreHeartbeatAck boolean? -- Whether to ignore the heartbeat acknowledgment (optional).
	@return Future -- A Future that resolves when the heartbeat is sent.
]=]
function DiscordShard.Prototype.heartbeatAsync(self: DiscordShard, ignoreHeartbeatAck: boolean?)
	return Future.try(function()
		if not ignoreHeartbeatAck then
			if not self.heartbeatAck then
				self.reporter:warn(`Discord Websocket state has become zombified, attempting to reconnect!`)

				self:reconnectAsync():await()
			end

			self.heartbeatAck = nil
		end

		self.heartbeatClockTime = os.clock()

		self.discordWebsocket
			:sendAsync({
				[WebsocketOperationKeys.OperationCode] = WebsocketOperationCodes.Heartbeat,
				[WebsocketOperationKeys.Data] = self.dispatchSequence or false,
			})
			:await()
	end)
end

--[=[
	Schedules the next heartbeat.
	
	@private
	@method heartbeatIn
	@within Network.DiscordShard
	@param milliseconds number -- The interval in milliseconds before the next heartbeat.
]=]
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

--[=[
	Identifies the Discord client with the Discord WebSocket.
	
	@private
	@method identifyAsync
	@within Network.DiscordShard
	@return Future -- A Future that resolves when the client is identified.
]=]
function DiscordShard.Prototype.identifyAsync(self: DiscordShard)
	return Future.try(function()
		self.discordWebsocket
			:sendAsync({
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
						self.discordClient.shardCount,
					},
				},
			})
			:await()
	end)
end

--[=[
	Connects the DiscordShard to the Discord WebSocket.
	
	@private
	@method connectAsync
	@param websocketUrl string -- The WebSocket URL.
	@within Network.DiscordShard
	@return Future -- A Future that resolves when the shard is connected.
]=]
function DiscordShard.Prototype.connectAsync(self: DiscordShard, websocketUrl: string)
	self.websocketUrl = websocketUrl

	return self.discordWebsocket:connectAsync(websocketUrl)
end

--[=[
	Resumes a previous session with the Discord WebSocket.
	
	@private
	@method resumeAsync
	@within Network.DiscordShard
	@return Future -- A Future that resolves when the session is resumed.
]=]
function DiscordShard.Prototype.resumeAsync(self: DiscordShard)
	return Future.try(function()
		local gatewayUrl = self.resumeGatewayUrl

		self.discordWebsocket:connectAsync(gatewayUrl or self.websocketUrl):await()

		if gatewayUrl then
			self.discordWebsocket
				:sendAsync({
					[WebsocketOperationKeys.OperationCode] = WebsocketOperationCodes.Resume,
					[WebsocketOperationKeys.Data] = {
						token = self.discordClient.discordSettings.discordToken,
						session_id = self.resumeSessionId,
						seq = self.dispatchSequence,
					},
				})
				:await()
		end
	end)
end

--[=[
	Attempts to reconnect the DiscordShard to the Discord WebSocket.
	
	@private
	@method reconnectAsync
	@within Network.DiscordShard
	@return Future -- A Future that resolves when the shard is reconnected.
]=]
function DiscordShard.Prototype.reconnectAsync(self: DiscordShard)
	if self.heartbeatTask then
		Task.cancel(self.heartbeatTask)
	end

	return Future.try(function()
		self.discordWebsocket:disconnectAsync(tostring(1005)):await()

		Task.wait(math.random())

		self:resumeAsync():await()
	end)
end

--[=[
	Creates a new instance of DiscordShard.
	
	@private
	@function new
	@param discordClient any -- The Discord client object.
	@param shardId number -- The ID of the shard.
	@within Network.DiscordShard
	@return DiscordShard -- A new instance of DiscordShard.
]=]
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

		shardId = shardId,
	}, DiscordShard.Prototype) :: any

	self:initiateWebsocket()

	return self
end

export type DiscordShard = typeof(DiscordShard.Prototype) & {
	discordWebsocket: DiscordWebsocket.DiscordWebsocket,
	discordClient: any,

	websocketUrl: string,

	reporter: Console.Console,

	heartbeatTask: thread?,
	resumeSessionId: string,
	dispatchSequence: number,
	heartbeatInterval: number,
	heartbeatClockTime: number,
	heartbeatPing: number,

	identified: boolean?,

	resumeGatewayUrl: string?,

	heartbeatAck: boolean?,
	heartbeatClockTime: number?,

	activeConnections: { Signal.Connection },

	onEvent: Signal.Signal<string, { [any]: any }>,

	shardId: number,
}

return DiscordShard.Interface
