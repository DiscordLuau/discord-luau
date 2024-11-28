--[[
	State class, this class is responsible for storing the state of the bot as
	as well as providing a way to interact with the state.

	This class is responsible for storing the following elements:
	- Token
	- Discord Cache
	- Discord REST API
	- Discord Gateway Manager

]]

local cache = require("./cache")
local rest = require("./rest")

local secret = require("../luau_packages/secret")
local apiTypes = require("../lune_packages/api_types")
local websocket = require("../lune_packages/websocket")

local State = {}

State.Interface = {}
State.Prototype = {}

function State.Prototype.setApplicationId(self: State, applicationId: apiTypes.Snowflake)
	self.applicationId = applicationId
end

--[[
	Constructor for the State class.
]]
function State.Interface.new(token: string, intents: number, version: number): State
	local secretToken = secret.new(token)

	local self = setmetatable(
		{
			token = secretToken,
			applicationId = "",

			rest = rest.new(secretToken, intents, version),
			webSocketManager = websocket.manager.new({
				token = secretToken,
				intents = intents,
				webSocketVersion = version,
				largeThreshold = 250,
			}),

			intents = intents,
			version = version,

			cache = {
				guilds = cache.new(30 * 60 * 60),
				users = cache.new(30 * 60 * 60),
				channels = cache.new(30 * 60 * 60),
				roles = cache.new(30 * 60 * 60),
				emojis = cache.new(30 * 60 * 60),
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
		emojis: cache.Cache<apiTypes.Snowflake, apiTypes.EmojiObject>,
	},
}

return State.Interface
