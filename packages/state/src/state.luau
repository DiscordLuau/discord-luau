--[=[
	@class State.State
	@__index Prototype

	State class, this class is responsible for storing the state of the bot as
	as well as providing a way to interact with the state.

	This class is responsible for storing the following elements:
	- Token
	- Discord Cache
	- Discord REST API
	- Discord Gateway Manager
]=]

--[=[
	@prop token Secret
	@within State.State
]=]

--[=[
	@prop applicationId string
	@within State.State
]=]

--[=[
	@prop rest State.Rest
	@within State.State
]=]

--[=[
	@prop webSocketManager WebSocket.Manager
	@within State.State
]=]

--[=[
	@prop intents number
	@within State.State
]=]

--[=[
	@prop version number
	@within State.State
]=]

--[=[
	@interface cache
	@within State.State
		.guilds Cache<apiTypes.Snowflake, apiTypes.GuildObject>
		.users Cache<apiTypes.Snowflake, apiTypes.UserObject>
		.channels Cache<apiTypes.Snowflake, apiTypes.ChannelObject>
		.roles Cache<apiTypes.Snowflake, apiTypes.GuildRoleObject>
]=]

local cache = require("./cache")
local rest = require("./rest")

local secret = require("../luau_packages/secret")
local apiTypes = require("../lune_packages/api_types")
local logger = require("../lune_packages/logger")
local websocket = require("../lune_packages/websocket")

local State = {}

State.Interface = {}
State.Prototype = {}

--[=[
	@within State.State

	Will set the current application ID
]=]
function State.Prototype.setApplicationId(self: State, applicationId: apiTypes.Snowflake)
	self.applicationId = applicationId
end

--[=[
	@within State.State

	Constructor for the State class.
]=]
function State.Interface.new(settings: {
	token: string,
	intents: number,
	version: number,
	reconnect: boolean,
	globalRatelimit: number,
	logLevel: logger.LogLevel?,
}): State
	local secretToken = secret.new(settings.token)

	local self = setmetatable(
		{
			token = secretToken,
			applicationId = "",

			rest = rest.new({
				token = secretToken,
				logLevel = settings.logLevel,
				intents = settings.intents,
				version = settings.version,
				globalRatelimit = settings.globalRatelimit,
			}),

			webSocketManager = websocket.manager.new({
				token = secretToken,
				intents = settings.intents,
				webSocketVersion = settings.version,
				largeThreshold = 250,
				reconnect = settings.reconnect,
			}),

			intents = settings.intents,
			version = settings.version,

			cache = {
				guilds = cache.new(1 * 60 * 60),
				users = cache.new(1 * 60 * 60),
				channels = cache.new(1 * 60 * 60),
				roles = cache.new(1 * 60 * 60),
			},
		} :: State,
		{
			__index = State.Prototype,
		}
	)

	return self
end

export type State = typeof(State.Prototype) & {
	token: secret.Secret<string>,
	applicationId: apiTypes.Snowflake,
	rest: rest.REST,
	webSocketManager: websocket.Manager,
	intents: number,
	version: number,
	cache: {
		guilds: cache.Cache<apiTypes.Snowflake, apiTypes.GuildObject>,
		users: cache.Cache<apiTypes.Snowflake, apiTypes.UserObject>,
		channels: cache.Cache<apiTypes.Snowflake, apiTypes.ChannelObject>,
		roles: cache.Cache<apiTypes.Snowflake, apiTypes.GuildRoleObject>,
	},
}

return State.Interface
