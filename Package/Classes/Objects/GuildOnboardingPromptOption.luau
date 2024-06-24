local Construct = require("@Utils/Construct")

local DiscordEmoji = require("@Objects/DiscordEmoji")

local CacheType = require("@Enums/CacheType")

--[=[
	@class Objects.GuildOnboardingPromptOption

	The `GuildOnboardingPromptOption` class provides a way for developers to interact with a guild onboarding prompt option.
]=]

--[=[
	@prop id string
	@within Objects.GuildOnboardingPromptOption
]=]

--[=[
	@prop channelIds { string }
	@within Objects.GuildOnboardingPromptOption
]=]

--[=[
	@prop roleIds { string }
	@within Objects.GuildOnboardingPromptOption
]=]

--[=[
	@prop title string
	@within Objects.GuildOnboardingPromptOption
]=]

--[=[
	@prop description string?
	@within Objects.GuildOnboardingPromptOption
]=]

local GuildOnboardingPromptOption = {}

GuildOnboardingPromptOption.Prototype = {}
GuildOnboardingPromptOption.Interface = {}

--[=[
	@prop type string
	@within Objects.GuildOnboardingPromptOption
	@readonly

	The type of the GuildOnboardingPromptOption. Default is "GuildOnboardingPromptOption".
]=]
GuildOnboardingPromptOption.Prototype.type = "GuildOnboardingPromptOption"

--[=[
	Creates a new GuildOnboardingPromptOption instance.

	@function new
	@return GuildOnboardingPromptOption
	@within Objects.GuildOnboardingPromptOption
]=]
function GuildOnboardingPromptOption.Interface.new(
	discordClient: any,
	onboardingPromptData: {
		id: string,

		[string]: any,
	}
)
	local self = discordClient.discordCache:getDataOr(
		CacheType.OnboardingPromptOption,
		onboardingPromptData.id,
		function()
			return Construct({
				id = onboardingPromptData.id,

				discordClient = discordClient,
			}, discordClient.Prototype)
		end
	)

	if onboardingPromptData.emoji then
		onboardingPromptData.emoji = DiscordEmoji.new(discordClient, onboardingPromptData.emoji)
	end

	for index, value in onboardingPromptData do
		self[index] = value
	end

	return self
end

export type GuildOnboardingPromptOption = typeof(GuildOnboardingPromptOption.Prototype) & {
	id: string,
	channelIds: { string },
	roleIds: { string },
	emoji: DiscordEmoji.DiscordEmoji,
	title: string,
	description: string?,
}

return GuildOnboardingPromptOption.Interface
