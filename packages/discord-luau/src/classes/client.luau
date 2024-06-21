local Task = require("@std/task")

local Console = require("@dep/console")
local Future = require("@dep/future")
local Signal = require("@dep/signal")

local construct = require("@util/construct")

local DiscordGateway = require("@network/gateway")
local DiscordShard = require("@network/shard")

local SettingsBuilder = require("@builders/settings")
local PresenceBuilder = require("@builders/presence")
local GuildBuilder = require("@builders/guild")

local EndpointCache = require("@classes/cache/endpoint")
local DiscordCache = require("@classes/cache")
local DiscordUser = require("@classes/user")
local DiscordGuild = require("@classes/guild")
local DiscordChannel = require("@classes/channel")
local DiscordMessage = require("@classes/message")
local DiscordApplication = require("@classes/application")
local DiscordInteraction = require("@classes/interaction")
local EventManager = require("@classes/eventManager")

local DiscordEndpoints = require("@data/endpoints")

local WebsocketEvents = require("@enums/websocket/events")
local DiscordEvents = require("@enums/discordEvents")
local WebsocketOperationCodes = require("@enums/websocket/operationCodes")
local WebsocketOperationKeys = require("@enums/websocket/operationKeys")

local CONCURRENT_IDENTIFY_YIELD = 5

--[=[
	@class DiscordClient

	The base class that implements the various properties, methods, and events that developers can use to interact with the Discord API.

	```lua
	local DiscordLuau = require("../Submodules/DiscordLuau")

	local SettingsBuilder = DiscordLuau.SettingsBuilder.new("BOT TOKEN")
	local DiscordClient = DiscordLuau.DiscordClient.new(SettingsBuilder)
	```
]=]
local DiscordClient = {}

DiscordClient.Prototype = {}
DiscordClient.Interface = {}

DiscordClient.Prototype.type = "DiscordClient"

--[=[
	@method connectAsync
	@within DiscordClient

	@return Vendor.Future

	Connects the current DiscordClient to the Discord API.

	```lua
	local DiscordClient = DiscordLuau.DiscordClient.new(SettingsBuilder)

	DiscordClient:connectAsync():after(function()
		print("Connected to the Discord API!")
	end)
	```
]=]
function DiscordClient.Prototype.connectAsync(self: DiscordClient)
	return Future.try(function()
		self.discordGateway:setEndpointCache(DiscordEndpoints.BotGateway, EndpointCache.new(10))

		local gatewayData = self.discordGateway:getAsync(DiscordEndpoints.BotGateway):await()
		local websocketVersion = self.discordGateway:getApiVersion()

		self.websocketUrl = `{gatewayData.url}/?v={websocketVersion}` :: string
		self.maxConcurrency = gatewayData.sessionStartLimit.maxConcurrency :: number
		self.shardCount = gatewayData.shards :: number

		for shardId = 1, self.shardCount do
			self.discordShards[shardId] = DiscordShard.new(self, shardId - 1)
		end

		for bucketIndex = 1, self.shardCount, self.maxConcurrency do
			for shardId = bucketIndex, (bucketIndex - 1) + self.maxConcurrency do
				self.discordShards[shardId]:connectAsync(self.websocketUrl):await()
			end

			if self.shardCount > self.maxConcurrency then
				Task.wait(CONCURRENT_IDENTIFY_YIELD)
			end
		end

		for shardId = 1, self.shardCount do
			local shard = self.discordShards[shardId]

			shard.onEvent:connect(function(eventName, data)
				if eventName == WebsocketEvents.Ready then
					--[=[
						@prop discordUser DiscordUser
						@within DiscordClient
					]=]
					self.discordUser = DiscordUser.new(self, data.user)
					--[=[
						@prop discordApplication DiscordApplication
						@within DiscordClient
					]=]
					self.discordApplication = DiscordApplication.new(self, data.application)

					self.onEvent:fire(DiscordEvents.Ready)
				elseif eventName == WebsocketEvents.MessageCreate then
					local discordMessage = DiscordMessage.new(self, data)

					self.onEvent:fire(DiscordEvents.Message, discordMessage)
				elseif eventName == WebsocketEvents.MessageUpdate then
					local discordMessage = DiscordMessage.new(self, data)

					self.onEvent:fire(DiscordEvents.MessageChanged, discordMessage)
				elseif eventName == WebsocketEvents.MessageDeleted then
					local discordMessage = DiscordMessage.new(self, data)

					self.onEvent:fire(DiscordEvents.MessageDeleted, discordMessage)
				elseif eventName == WebsocketEvents.InteractionCreate then
					local discordInteraction = DiscordInteraction.new(self, data)

					self.onEvent:fire(DiscordEvents.Interaction, discordInteraction)
				elseif eventName == WebsocketEvents.MessageBulkDeleted then
					self.onEvent:fire(DiscordEvents.MessageBulkDeleted, data)
				elseif eventName == WebsocketEvents.ChannelCreate then
					local discordChannel = DiscordChannel.from(self, data)

					self.onEvent:fire(DiscordEvents.ChannelCreate, discordChannel)
				elseif eventName == WebsocketEvents.ChannelUpdate then
					local discordChannel = DiscordChannel.from(self, data)

					self.onEvent:fire(DiscordEvents.ChannelUpdate, discordChannel)
				elseif eventName == WebsocketEvents.ChannelDeleted then
					local discordChannel = DiscordChannel.from(self, data)

					self.onEvent:fire(DiscordEvents.ChannelDelete, discordChannel)
				elseif eventName == WebsocketEvents.UserUpdated then
					self.discordUser = DiscordUser.new(self, data.user)

					self.onEvent:fire(DiscordEvents.UserUpdated, self.discordUser)
				elseif eventName == WebsocketEvents.ChannelPinsUpdate then
					self.onEvent:fire(DiscordEvents.ChannelPinsUpdate, data)
				elseif eventName == WebsocketEvents.GuildCreate then
					local discordGuild = DiscordGuild.new(self, data)

					self.onEvent:fire(DiscordEvents.GuildCreate, discordGuild)
				elseif eventName == WebsocketEvents.GuildUpdate then
					local discordGuild = DiscordGuild.new(self, data)

					self.onEvent:fire(DiscordEvents.GuildCreate, discordGuild)
				elseif eventName == WebsocketEvents.GuildDeleted then
					local discordGuild = DiscordGuild.new(self, data)

					self.onEvent:fire(DiscordEvents.GuildCreate, discordGuild)
				elseif eventName == WebsocketEvents.GuildMemberBanned then
					data.user = DiscordUser.new(self, data.user)

					self.onEvent:fire(DiscordEvents.GuildMemberBanned, data)
				elseif eventName == WebsocketEvents.GuildMemberUnbanned then
					data.user = DiscordUser.new(self, data.user)

					self.onEvent:fire(DiscordEvents.GuildMemberUnbanned, data)
				elseif eventName == WebsocketEvents.GuildMemberJoined then
					data.user = DiscordUser.new(self, data.user)

					self.onEvent:fire(DiscordEvents.GuildMemberJoined, data)
				elseif eventName == WebsocketEvents.GuildMemberLeft then
					data.user = DiscordUser.new(self, data.user)

					self.onEvent:fire(DiscordEvents.GuildMemberLeft, data)
				elseif eventName == WebsocketEvents.GuildMemberUpdated then
					data.user = DiscordUser.new(self, data.user)

					self.onEvent:fire(DiscordEvents.GuildMemberUpdated, data)
				else
					self.reporter:debug(`Unknown Event: '{eventName}'`)
				end
			end)
		end
	end)
end

--[=[
	Fetches a guild by its ID.
	
	@method fetchGuildAsync
	@param guildId string -- The ID of the guild to fetch.
	@within DiscordClient
	@return Vendor.Future<DiscordGuild> -- A future resolving to the fetched DiscordGuild.
]=]
function DiscordClient.Prototype.fetchGuildAsync(
	self: DiscordClient,
	guildId: string
): Future.Future<DiscordGuild.DiscordGuild>
	return Future.try(function()
		local rawGuildData = self.discordGateway:getAsync(string.format(DiscordEndpoints.BotGetGuild, guildId)):await()

		return DiscordGuild.new(self, rawGuildData)
	end)
end

--[=[
	
	Fetches a channel by its ID.
	
	@method fetchChannelAsync
	@param channelId string -- The ID of the channel to fetch.
	@within DiscordClient
	@return Vendor.Future<Objects.DiscordChannel> -- A future resolving to the fetched DiscordChannel.
]=]
function DiscordClient.Prototype.fetchChannelAsync(
	self: DiscordClient,
	channelId: string
): Future.Future<DiscordChannel.DiscordChannel>
	return Future.try(function()
		local rawChannelData =
			self.discordGateway:getAsync(string.format(DiscordEndpoints.BotGetChannel, channelId)):await()

		return DiscordChannel.from(self, rawChannelData) :: DiscordChannel.DiscordChannel
	end)
end

--[=[
	Updates the client's presence.
	
	@method updatePresenceAsync
	@param discordPresence table -- The presence data to update.
	@within DiscordClient
	@return Vendor.Future<boolean> -- A future resolving to a boolean indicating success.
]=]
function DiscordClient.Prototype.updatePresenceAsync(
	self: DiscordClient,
	discordPresence: PresenceBuilder.PresenceBuilder
): Future.Future<boolean>
	return Future.try(function()
		for shardId = 1, self.shardCount do
			(self.discordShards :: { DiscordShard.DiscordShard })[shardId].discordWebsocket
				:sendAsync({
					[WebsocketOperationKeys.OperationCode] = WebsocketOperationCodes.PresenseUpdate,
					[WebsocketOperationKeys.Data] = discordPresence:toPayloadObject():resolve(),
				})
				:await()
		end

		return true
	end)
end

--[=[
	Creates a Guild, owned by the application.
	
	@method createGuildAsync
	@param guildBuilder Builders.GuildBuilder
	@within DiscordClient
	@return Vendor.Future<DiscordGuild>
]=]
function DiscordClient.Prototype.createGuildAsync(
	self: DiscordClient,
	guildBuilder: GuildBuilder.GuildBuilder
): Future.Future<DiscordGuild.DiscordGuild>
	return Future.try(function()
		local rawGuildData: any =
			self.discordGateway:postAsync(DiscordEndpoints.BotCreateGuild, guildBuilder:toPayloadObject()):await()

		return DiscordGuild.new(self, rawGuildData)
	end)
end

--[=[
	Sets the verbosity level for logging.
	
	@method setVerbose
	@within DiscordClient
	@param verbose boolean -- Whether to enable verbose logging.
]=]
function DiscordClient.Prototype.setVerbose(_: DiscordClient, verbose: boolean)
	Console.setGlobalLogLevel(verbose and Console.LogLevel.debug or Console.LogLevel.warn)
end

--[=[
	constructor function for the Discord Client, used to instantiate a Discord Client object.
		
	@function new
	@param discordSettings SettingsBuilder -- The settings builder for the client.
	@within DiscordClient
	@return DiscordClient -- A new instance of DiscordClient.

	```lua
	local DiscordClient = DiscordLuau.DiscordClient.new(SettingsBuilder)

	DiscordClient:connectAsync():after(function()
		print("Connected to the Discord API!")
	end)
	```
]=]
function DiscordClient.Interface.new(discordSettings: SettingsBuilder.SettingsBuilder): DiscordClient
	local self = construct({
		--[=[
			@prop discordSettings SettingsBuilder
			@within DiscordClient
		]=]
		discordSettings = discordSettings,

		--[=[
			@prop discordCache DiscordCache
			@within DiscordClient
		]=]
		discordCache = DiscordCache.new(),

		--[=[
			@prop reporter Vendor.Reporter
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
			@prop discordShards { Network.DiscordShard }
			@within DiscordClient
		]=]
		discordShards = {},

		--[=[
			@prop onEvent Vendor.Signal<string, { [any]: any }?>
			@within DiscordClient
		]=]
		onEvent = Signal.new(),
	}, DiscordClient.Prototype) :: any

	--[=[
		@prop discordGateway Objects.DiscordGateway
		@within DiscordClient
	]=]
	self.discordGateway = DiscordGateway.new(self :: any)

	--[=[
		@prop eventManager Objects.EventManager
		@within DiscordClient
	]=]
	self.eventManager = EventManager.new(self :: any)

	return self
end

Console.setGlobalLogLevel(Console.LogLevel.warn)

export type DiscordClient = typeof(DiscordClient.Prototype) & {
	discordGateway: DiscordGateway.DiscordGateway,
	discordSettings: SettingsBuilder.SettingsBuilder,
	discordCache: DiscordCache.DiscordCache,

	eventManager: EventManager.EventManager,

	websocketUrl: string,
	shardCount: number,
	maxConcurrency: number,

	onEvent: Signal.Signal<string, { [any]: any }?>,

	reporter: Console.Console,

	discordShards: { DiscordShard.DiscordShard },

	discordUser: DiscordUser.DiscordUser,
	discordApplication: DiscordApplication.DiscordApplication,
}

return DiscordClient.Interface
