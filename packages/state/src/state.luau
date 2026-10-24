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
	@prop userId string
	@within State.State

	The bot's own user ID, set from READY; voice connections identify with it. Empty until READY.
]=]

--[=[
	@prop logger logger.Logger
	@within State.State

	The shared state's logger, for packages without their own.
]=]

--[=[
	@prop voiceConnections { [string]: voice.Connection }
	@within State.State

	The bot's voice connection in each guild, keyed by guild ID.
]=]

--[=[
	@prop stub Stub?
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
local apiTypes = require("../luau_packages/api_types")
local logger = require("../luau_packages/logger")
local websocket = require("../luau_packages/websocket")

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

	Will set the bot's own user ID, which voice connections identify with.
]=]
function State.Prototype.setUserId(self: State, userId: apiTypes.Snowflake)
	self.userId = userId
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
	isUsingStub: Stub?,
}): State
	local stub = settings.isUsingStub
	local restUrl: string? = stub and stub.restUrl
	local secretToken = secret.new(settings.token)

	assert(not stub or restUrl, "isUsingStub requires a stub with an HTTP server - call stub:createHttpServer() first")

	local self = setmetatable(
		{
			token = secretToken,
			applicationId = "",
			userId = "",
			logLevel = settings.logLevel or "Warn" :: any,
			logger = logger.new("State", settings.logLevel),
			stub = stub,

			rest = rest.new({
				token = secretToken,
				logLevel = settings.logLevel,
				intents = settings.intents,
				version = settings.version,
				globalRatelimit = settings.globalRatelimit,
				baseUrl = restUrl,
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
				guilds = cache.new(),
				users = cache.new(),
				channels = cache.new(),
				roles = cache.new(),
			},

			voiceConnections = {} :: { [string]: any },
		} :: State,
		{
			__index = State.Prototype,
		}
	)

	return self
end

export type Stub = {
	restUrl: string?,
}

export type State = typeof(State.Prototype) & {
	token: secret.Secret<string>,
	applicationId: apiTypes.Snowflake,
	userId: apiTypes.Snowflake,
	logger: logger.Logger,
	logLevel: logger.LogLevel,
	stub: Stub?,
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
	voiceConnections: { [string]: any },
}

return State.Interface
