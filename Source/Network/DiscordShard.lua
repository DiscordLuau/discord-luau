local WebsocketOperationCodes = require("../Enums/WebsocketOperationCodes")
local WebsocketOperationKeys = require("../Enums/WebsocketOperationKeys")

local WebsocketEvents = require("../Enums/WebsocketEvents")

local Promise = require("../Dependencies/Github/Promise")
local Console = require("../Dependencies/Github/Console")
local Provider = require("../Dependencies/Provider")
local Observer = require("../Dependencies/Observer")

local DiscordWebsocket = require("DiscordWebsocket")

local Process = require("@lune/process")
local Task = require("@lune/task")

local LIBRARY_IDENTIFIER = "DiscordU"

local DiscordShard = {}

DiscordShard.Type = "DiscordShard"

DiscordShard.Internal = {}
DiscordShard.Interface = {}
DiscordShard.Prototype = {
	Internal = DiscordShard.Internal,
}

function DiscordShard.Prototype:ObserveWebsocketEvents()
	self.EventProvider:Subscribe(Observer.new(WebsocketEvents.Ready, function(data)
		local websocketVersion = self.DiscordClient.Gateway:GetApiVersion()

		self.Reporter:Log(`DiscordShard is active - id: "{data.session_id}"`)

		self.ResumeSessionId = data.session_id
		self.ResumeGatewayUrl = `{data.resume_gateway_url}/?v={websocketVersion}`
	end))
end

function DiscordShard.Prototype:ObserveWebsocketOperations()
	self.DiscordWebsocket.OperationProvider:Subscribe(Observer.new(WebsocketOperationCodes.Dispatch, function(data, eventName, sequence)
		self.DispatchSequence = sequence

		self.EventProvider:InvokeObservers(eventName, data)
	end))

	self.DiscordWebsocket.OperationProvider:Subscribe(Observer.new(WebsocketOperationCodes.Hello, function(data)
		Task.wait(math.random())

		self:HeartbeatAsync(true):andThen(function()
			self:HeartbeatIn(data.heartbeat_interval * math.random())
		end)
	end))

	self.DiscordWebsocket.OperationProvider:Subscribe(Observer.new(WebsocketOperationCodes.Heartbeat, function()
		self.Reporter:Log(`Discord Websocket requested heartbeat, sending heartbeat!`)

		self:HeartbeatAsync(true)
	end))

	self.DiscordWebsocket.OperationProvider:Subscribe(Observer.new(WebsocketOperationCodes.HeartbeatACK, function()
		self.HeartbeatAck = true

		if not self.Identified then
			self.Identified = true

			self:IdentifyAsync():catch(function()
				self.Identified = nil
			end)
		end
	end))

	self.DiscordWebsocket.OperationProvider:Subscribe(Observer.new(WebsocketOperationCodes.Reconnect, function()
		self.Reporter:Log(`Discord Websocket requested reconnect, attempting to reconnect!`)

		self:ReconnectAsync()
	end))

	self.DiscordWebsocket.OperationProvider:Subscribe(Observer.new(WebsocketOperationCodes.InvalidSession, function(data)
		self.Reporter:Warn(`Discord Websocket session invalid!`)

		if data == true then
			self.Reporter:Log(`Attempting to reconnect from Invalid Session!`)

			self:ReconnectAsync()
		else
			error(`Discord session was invalidated, please ensure that the bot's permissions & token is correct!`)
		end
	end))
end

function DiscordShard.Prototype:HeartbeatAsync(ignoreHeartbeatAck)
	return Promise.new(function(resolve, reject)
		if not ignoreHeartbeatAck then
			if not self.HeartbeatAck then
				self.Reporter:Warn(`Discord Websocket state has become zombified, attempting to reconnect!`)

				return self:ReconnectAsync():andThen(function()
					resolve()
				end):catch(function(exception)
					reject(exception)
				end)
			end

			self.HeartbeatAck = nil
		end

		local success, response = self.DiscordWebsocket:SendAsync({
			[WebsocketOperationKeys.OperationCode] = WebsocketOperationCodes.Heartbeat,
			[WebsocketOperationKeys.Data] = self.DispatchSequence or false,
		}):await()

		if success then
			resolve(response)
		else
			reject(response)
		end
	end)
end

function DiscordShard.Prototype:HeartbeatIn(milliseconds)
	if self.HeartbeatTask then
		Task.cancel(self.HeartbeatTask)
	end

	self.HeartbeatTask = Task.delay(milliseconds / 1000, function()
		self.HeartbeatTask = nil

		self:HeartbeatAsync():await()
		self:HeartbeatIn(milliseconds)
	end)
end

function DiscordShard.Prototype:IdentifyAsync()
	return Promise.new(function(resolve, reject)
		self.DiscordWebsocket:SendAsync({
			[WebsocketOperationKeys.OperationCode] = WebsocketOperationCodes.Identify,
			[WebsocketOperationKeys.Data] = {
				["token"] = self.DiscordClient.DiscordToken,
				["intents"] = self.DiscordClient.DiscordIntents:ToJSONObject(),
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
		})
			:andThen(function()
				resolve()
			end)
			:catch(function(exception)
				reject(exception)
			end)
	end)
end

function DiscordShard.Prototype:ConnectAsync(...)
	return self.DiscordWebsocket:ConnectAsync(...)
end

function DiscordShard.Prototype:ResumeAsync()
	return self.DiscordWebsocket:ConnectAsync(self.ResumeGatewayUrl):andThen(function()
		self.DiscordWebsocket:SendAsync({
			[WebsocketOperationKeys.OperationCode] = WebsocketOperationCodes.Resume,
			[WebsocketOperationKeys.Data] = {
				token = self.DiscordClient.DiscordToken,
				session_id = self.ResumeSessionId,
				seq = self.DispatchSequence
			},
		})
	end)
end

function DiscordShard.Prototype:ReconnectAsync()
	if self.HeartbeatTask then
		Task.cancel(self.HeartbeatTask)
	end

	self.DiscordWebsocket:DisconnectAsync(1005):andThen(function()
		Task.wait(math.random())

		self:ResumeAsync()
	end)
end

function DiscordShard.Prototype:ToString()
	return `{DiscordShard.Type}<"{self.ShardId}">`
end

function DiscordShard.Interface.new(discordClient, shardId)
	local self = setmetatable({
		DiscordWebsocket = DiscordWebsocket.new(discordClient),
		DiscordClient = discordClient,

		Reporter = Console.new(`DiscordShard_{shardId}`),

		EventProvider = Provider.new(),

		ShardId = shardId
	}, {
		__index = DiscordShard.Prototype,
		__type = DiscordShard.Type,
		__tostring = function(object)
			return object:ToString()
		end,
	})

	self:ObserveWebsocketEvents()
	self:ObserveWebsocketOperations()

	return self
end

return DiscordShard.Interface
