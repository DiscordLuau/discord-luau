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

DiscordClient.Prototype.type = "DiscordClient"

function DiscordClient.Prototype.connectAsync(self: DiscordClient)
	return Future.try(function()
		self.DiscordGateway:setEndpointCache(DiscordEndpoints.BotGateway, Cache.new(10))

		local data = self.DiscordGateway:getAsync(DiscordEndpoints.BotGateway):await()
		local websocketVersion = self.DiscordGateway:getApiVersion()

		self.websocketUrl = `{data.url}/?v={websocketVersion}`
		self.shardCount = data.shards
		self.maxConcurrency = data.sessionStartLimit.maxConcurrency

		for shardId = 1, self.shardCount do
			self.discordShards[shardId] = DiscordShard.new(self, shardId - 1)
		end

		for bucketIndex = 1, self.shardCount, self.maxConcurrency do
			for shardId = bucketIndex, (bucketIndex - 1) + self.maxConcurrency do
				self.discordShards[shardId]:connectAsync(self.websocketUrl)
			end

			if self.shardCount > self.maxConcurrency then
				Task.wait(CONCURRENT_IDENTIFY_YIELD)
			end
		end

		for shardId = 1, self.shardCount do
			self.discordShards[shardId].onEvent:connect(function(eventName, data)
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
		discordSettings = discordSettings,

		reporter = Console.new("🎮 DiscordClient"),

		websocketUrl = "",
		shardCount = 0,
		maxConcurrency = 0,

		discordShards = { } :: { DiscordShard.DiscordShard },
		cache = { },
	}, DiscordClient.Prototype)

	self.DiscordGateway = DiscordGateway.new(self)

	return self
end

export type DiscordClient = typeof(DiscordClient.Interface.new()) & {
	DiscordGateway: DiscordGateway.DiscordGateway
}

return DiscordClient.Interface