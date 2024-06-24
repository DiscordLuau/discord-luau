local Construct = require("@Utils/Construct")

local DiscordChannel = require("@Objects/DiscordChannel")

local CacheType = require("@Enums/CacheType")

--[=[
	@class Objects.GuildWelcomeScreen

	The `GuildWelcomeScreen` class provides a way for developers to interact with a Welcome Screen.
]=]

--[=[
	@prop description string?
	@within Objects.GuildWelcomeScreen
]=]

--[=[
	@prop welcomeChannels { Objects.DiscordChannel }
	@within Objects.GuildWelcomeScreen
]=]

local GuildWelcomeScreen = {}

GuildWelcomeScreen.Prototype = {}
GuildWelcomeScreen.Interface = {}

--[=[
	@prop type string
	@within Objects.GuildWelcomeScreen
	@readonly

	The type of the GuildWelcomeScreen. Default is "GuildWelcomeScreen".
]=]
GuildWelcomeScreen.Prototype.type = "GuildWelcomeScreen"

--[=[
	Creates a new GuildWelcomeScreen instance.

	@function new
	@return GuildWelcomeScreen
	@within Objects.GuildWelcomeScreen
]=]
function GuildWelcomeScreen.Interface.new(
	discordClient: any,
	welcomeScreenData: {
		id: string,

		[string]: any,
	}
)
	local self = discordClient.discordCache:getDataOr(CacheType.WelcomeScreen, welcomeScreenData.id, function()
		return Construct({
			id = welcomeScreenData.id,

			discordClient = discordClient,
		}, discordClient.Prototype)
	end)

	if welcomeScreenData.welcomeChannels then
		for index, value in welcomeScreenData.channels do
			welcomeScreenData.welcomeChannels[index] = DiscordChannel.from(discordClient, value)
		end
	end

	for index, value in welcomeScreenData do
		self[index] = value
	end

	return self
end

export type GuildWelcomeScreen = typeof(GuildWelcomeScreen.Prototype) & {
	description: string?,
	welcomeChannels: { DiscordChannel.DiscordChannel },
}

return GuildWelcomeScreen.Interface
