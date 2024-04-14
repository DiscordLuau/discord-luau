local DiscordSettings = require("DiscordSettings")

local Construct = require("../Utils/Construct")

local DiscordGateway = require("Network/DiscordGateway")
local DiscordShard = require("Network/DiscordShard")

local DiscordEndpoints = require("../Enums/DiscordEndpoints")
local WebsocketEvents = require("../Enums/WebsocketEvents")

local Cache = require("Internal/Cache")

local Console = require("../Vendor/Console")
local Future = require("../Vendor/Future")

local Task = require("@lune/task")

local CONCURRENT_IDENTIFY_YIELD = 5

local DiscordClient = {}

DiscordClient.Prototype = {}
DiscordClient.Interface = {}

function DiscordClient.Prototype.connectAsync(self: DiscordClient)
	return Future.try(function()
		self.DiscordGateway:setEndpointCache(DiscordEndpoints.BotGateway, Cache.new(10))

		local data = self.DiscordGateway:getAsync(DiscordEndpoints.BotGateway):await()
		local websocketVersion = self.DiscordGateway:getApiVersion()

		self.WebsocketUrl = `{data.url}/?v={websocketVersion}`
		self.ShardCount = data.shards
		self.MaxConcurrency = data.session_start_limit.max_concurrency

		for shardId = 1, self.ShardCount do
			self.DiscordShards[shardId] = DiscordShard.new(self, shardId - 1)
		end

		for bucketIndex = 1, self.ShardCount, self.MaxConcurrency do
			for shardId = bucketIndex, (bucketIndex - 1) + self.MaxConcurrency do
				self.DiscordShards[shardId]:connectAsync(self.WebsocketUrl)
			end

			if self.ShardCount > self.MaxConcurrency then
				Task.wait(CONCURRENT_IDENTIFY_YIELD)
			end
		end

		for shardId = 1, self.ShardCount do
			self.DiscordShards[shardId].OnEvent:connect(function(eventName, data)
				if eventName == WebsocketEvents.Ready then
					print("READY!")
				elseif eventName == WebsocketEvents.MessageCreate then
					print("MESSAGE CREATE!")
				end
			end)
		end
	end)
end

function DiscordClient.Interface.new(discordSettings: DiscordSettings.DiscordSettings)
	local self = Construct({
		DiscordSettings = discordSettings,

		Reporter = Console.new("DiscordClient"),

		WebsocketUrl = "",
		ShardCount = 0,
		MaxConcurrency = 0,

		DiscordShards = { } :: { DiscordShard.DiscordShard },
		Cache = { },
	}, DiscordClient.Prototype)

	self.DiscordGateway = DiscordGateway.new(self)

	return self
end

export type DiscordClient = typeof(DiscordClient.Interface.new()) & {
	DiscordGateway: DiscordGateway.DiscordGateway
}

return DiscordClient.Interface