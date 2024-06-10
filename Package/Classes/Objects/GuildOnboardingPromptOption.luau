local Construct = require("@Utils/Construct")

local DiscordEmoji = require("@Objects/DiscordEmoji")

local CacheType = require("@Enums/CacheType")

--[=[
	@class Objects.GuildOnboardingPrompt

	The `GuildOnboardingPrompt` class provides a way for developers to interact with a guild onboarding prompt option.
]=]
local GuildOnboardingPrompt = {}

GuildOnboardingPrompt.Prototype = {}
GuildOnboardingPrompt.Interface = {}

--[=[
	@prop type string
	@within Objects.GuildOnboardingPrompt
	@readonly

	The type of the GuildOnboardingPrompt. Default is "GuildOnboardingPrompt".
]=]
GuildOnboardingPrompt.Prototype.type = "GuildOnboardingPrompt"

--[=[
	Creates a new GuildOnboardingPrompt instance.

	@function new
	@return GuildOnboardingPrompt
	@within Objects.GuildOnboardingPrompt
]=]
function GuildOnboardingPrompt.Interface.new(
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

export type GuildOnboardingPrompt = typeof(GuildOnboardingPrompt.Prototype) & {
	id: string,
	channelIds: { string },
	roleIds: { string },
	emoji: DiscordEmoji.DiscordEmoji,
	title: string,
	description: string?,
}

return GuildOnboardingPrompt.Interface
