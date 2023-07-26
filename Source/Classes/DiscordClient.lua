local WebsocketOperationCodes = require("../Enums/WebsocketOperationCodes")
local WebsocketOperationKeys = require("../Enums/WebsocketOperationKeys")
local DiscordEndpoints = require("../Enums/DiscordEndpoints")
local WebsocketEvents = require("../Enums/WebsocketEvents")

local Console = require("../Dependencies/Github/Console")
local Promise = require("../Dependencies/Github/Promise")

local Cache = require("../Dependencies/Cache")
local Observer = require("../Dependencies/Observer")
local Provider = require("../Dependencies/Provider")

local DiscordShard = require("../Network/DiscordShard")
local DiscordGateway = require("../Network/DiscordGateway")

local DiscordUser = require("Internal/DiscordUser")
local DiscordMember = require("Internal/DiscordMember")
local DiscordChannel = require("Internal/DiscordChannel")
local DiscordApplication = require("Internal/DiscordApplication")
local DiscordGuild = require("Internal/DiscordGuild")

local DiscordMessage = require("DiscordMessage")

local Task = require("@lune/task")

local CONCURRENT_IDENTIFY_YIELD = 5

local DiscordClient = {}

DiscordClient.Type = "DiscordClient"

DiscordClient.Internal = {}
DiscordClient.Interface = {}
DiscordClient.Prototype = {
	Internal = DiscordClient.Internal,
}

function DiscordClient.Prototype:ConnectAsync()
	return Promise.new(function(resolve, reject)
		self.Gateway = DiscordGateway.new(self)

		self.Gateway:SetEndpointCache(DiscordEndpoints.BotGateway, Cache.new(10))
		self.Gateway:GetAsync(DiscordEndpoints.BotGateway):andThen(function(data)
			local websocketVersion = self.Gateway:GetApiVersion()

			self.WebsocketUrl = `{data.url}/?v={websocketVersion}`
			self.ShardCount = data.shards
			self.MaxConcurrency = data.session_start_limit.max_concurrency

			for shardId = 1, self.ShardCount do
				self.DiscordShards[shardId] = DiscordShard.new(self, shardId - 1)
			end

			for bucketIndex = 1, self.ShardCount, self.MaxConcurrency do
				local connectionPromises = {}

				for shardId = bucketIndex, (bucketIndex - 1) + self.MaxConcurrency do
					table.insert(connectionPromises, self.DiscordShards[shardId]:ConnectAsync(self.WebsocketUrl))
				end

				local success, response = Promise.all(connectionPromises):await()

				if not success then
					return reject(response)
				end

				if self.ShardCount > self.MaxConcurrency then
					Task.wait(CONCURRENT_IDENTIFY_YIELD)
				end
			end

			resolve()
		end)
	end):andThen(function()
		for shardId = 1, self.ShardCount do
			self.DiscordShards[shardId].EventProvider:Subscribe(Observer.new(WebsocketEvents.MessageCreate, function(data)
				local discordAuthor = DiscordUser.from(self, data.author)
				local discordMessage = DiscordMessage.from(self, data, discordAuthor)
				local discordMember = DiscordMember.from(self, data.member, discordMessage)

				discordMessage.Member = discordMember

				self.Provider:InvokeObservers("OnMessage", discordMessage)
			end))

			self.DiscordShards[shardId].EventProvider:Subscribe(Observer.new(WebsocketEvents.Ready, function(data)
				for _shardId = 1, self.ShardCount do
					if not self.DiscordShards[_shardId].Identified then
						return
					end
				end

				self.User = DiscordUser.from(self, data.user)
				self.Application = DiscordApplication.from(self, data.application)

				for _, partialGuildObject in data.guilds do
					DiscordGuild.from(self, partialGuildObject)
				end

				self.Provider:InvokeObservers("OnReady")
			end))
		end
	end)
end

function DiscordClient.Prototype:SendAsync(data)
	local sendMessaagePromises = {}

	for shardId = 1, self.ShardCount do
		table.insert(sendMessaagePromises, self.DiscordShards[shardId].DiscordWebsocket:SendAsync(data))
	end

	return Promise.any(sendMessaagePromises)
end

function DiscordClient.Prototype:GetChannelAsync(channelId)
	return DiscordChannel.fetchAsync(self, channelId)
end

function DiscordClient.Prototype:UpdatePresenceAsync(discordPresence)
	return self:SendAsync({
		[WebsocketOperationKeys.OperationCode] = WebsocketOperationCodes.PresenseUpdate,
		[WebsocketOperationKeys.Data] = discordPresence:ToJSONObject(),
	})
end

function DiscordClient.Prototype:AddToCache(objectId, object)
	if self.Cache[objectId] then
		self.Reporter:Warn(`Object {objectId} already exists in cache - overwriting!`)
	end

	self.Cache[objectId] = object

	return self.Cache[objectId]
end

function DiscordClient.Prototype:RemoveFromCache(objectId)
	self.Cache[objectId] = nil
end

function DiscordClient.Prototype:GetFromCache(objectId)
	return self.Cache[objectId]
end

function DiscordClient.Prototype:Subscribe(eventName, eventCallback)
	local observer = Observer.new(eventName, eventCallback)

	self.Provider:Subscribe(observer)

	return observer
end

function DiscordClient.Prototype:Unsubscribe(observer)
	self.Provider:Unsubscribe(observer)
end

function DiscordClient.Prototype:SetVerboseLogging(isVerbose)
	if isVerbose then
		Console.setGlobalLogLevel(Console.LogLevel.Debug)
	else
		Console.setGlobalLogLevel(Console.LogLevel.Warn)
	end
end

function DiscordClient.Prototype:ToString()
	local safeDiscordToken = self.DiscordToken

	safeDiscordToken = string.sub(safeDiscordToken, 1, 40)
	safeDiscordToken ..= ` ...`

	return `{DiscordClient.Type}<"{safeDiscordToken}">`
end

function DiscordClient.Interface.new(discordSettings)
	local self = setmetatable({
		DiscordToken = discordSettings.DiscordToken,
		DiscordIntents = discordSettings.DiscordIntents,

		DiscordShards = { },
		Cache = { },

		Provider = Provider.new(),
	}, {
		__index = DiscordClient.Prototype,
		__type = DiscordClient.Type,
		__tostring = function(object)
			return object:ToString()
		end,
	})

	self:SetVerboseLogging(false)

	return self
end

return DiscordClient.Interface
