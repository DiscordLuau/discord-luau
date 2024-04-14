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

--[=[
	@class DiscordClient

	The base class that implements the various properties, methods and events that developers can use to interact with the Discord API.

	```lua
		local DiscordLuau = require("../Submodules/DiscordLuau")

		local DiscordSettings = DiscordLuau.DiscordSettings.new("BOT TOKEN")
		local DiscordClient = DiscordLuau.DiscordClient.new(DiscordSettings)

		...
	```
]=]
local DiscordClient = {}

DiscordClient.Prototype = {}
DiscordClient.Interface = {}

DiscordClient.Prototype.type = "DiscordClient"

--[=[
	@method connectAsync
	@within DiscordClient

	@return Future

	Connect the current DiscordClient to the Discord API

	```lua
		local DiscordClient = DiscordLuau.DiscordClient.new(DiscordSettings)

		DiscordClient:connectAsync():after(function()
			print("Connected to the Discord API!")
		end)
	```
]=]
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

--[=[
	@function new
	@within DiscordClient

	@return DiscordClient

	Constructor function for the Discord Client, this is where you'll be able to instantiate a Discord Client object.

	```lua
		local DiscordClient = DiscordLuau.DiscordClient.new(DiscordSettings)

		DiscordClient:connectAsync():after(function()
			print("Connected to the Discord API!")
		end)
	```
]=]
function DiscordClient.Interface.new(discordSettings: DiscordSettings.DiscordSettings)
	local self = Construct({
		--[=[
			@prop discordSettings DiscordSettings
			@within DiscordClient
		]=]
		discordSettings = discordSettings,

		--[=[
			@prop reporter Reporter
			@within DiscordClient
		]=]
		reporter = Console.new("🎮 DiscordClient"),

		--[=[
			@prop websocketUrl string
			@within DiscordClient
		]=]
		websocketUrl = "",

		--[=[
			@prop shardCount number
			@within DiscordClient
		]=]
		shardCount = 0,

		--[=[
			@prop maxConcurrency number
			@within DiscordClient
		]=]
		maxConcurrency = 0,

		--[=[
			@prop discordShards { DiscordShard }
			@within DiscordClient
		]=]
		discordShards = { } :: { DiscordShard.DiscordShard },
	}, DiscordClient.Prototype)

	--[=[
			@prop DiscordGateway DiscordGateway
			@within DiscordClient
		]=]
	self.DiscordGateway = DiscordGateway.new(self)

	return self
end

export type DiscordClient = typeof(DiscordClient.Interface.new()) & {
	DiscordGateway: DiscordGateway.DiscordGateway
}

return DiscordClient.Interface