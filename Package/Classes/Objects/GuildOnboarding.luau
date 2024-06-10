local Construct = require("@Utils/Construct")

local GuildOnboardingPrompt = require("@Objects/GuildOnboardingPrompt")

local CacheType = require("@Enums/CacheType")

--[=[
	@class Objects.GuildOnboarding

	The `GuildOnboarding` class provides a way for developers to interact with a Guild Onboarding.
]=]
local GuildOnboarding = {}

GuildOnboarding.Prototype = {}
GuildOnboarding.Interface = {}

--[=[
	@prop type string
	@within Objects.GuildOnboarding
	@readonly

	The type of the GuildOnboarding. Default is "GuildOnboarding".
]=]
GuildOnboarding.Prototype.type = "GuildOnboarding"

--[=[
	Creates a new GuildOnboarding instance.

	@function new
	@return GuildOnboarding
	@within Objects.GuildOnboarding
]=]
function GuildOnboarding.Interface.new(
	discordClient: any,
	onboardingData: {
		guildId: string,

		[string]: any,
	}
)
	local self = discordClient.discordCache:getDataOr(CacheType.OnboardingPrompt, onboardingData.guildId, function()
		return Construct({
			id = onboardingData.guildId,

			discordClient = discordClient,
		}, discordClient.Prototype)
	end)

	if onboardingData.prompts then
		for index, value in onboardingData.options do
			onboardingData.options[index] = GuildOnboardingPrompt.new(discordClient, value)
		end
	end

	for index, value in onboardingData do
		self[index] = value
	end

	return self
end

export type GuildOnboarding = typeof(GuildOnboarding.Prototype) & {
	guildId: string,
	prompts: { GuildOnboardingPrompt.GuildOnboardingPrompt },
	defaultChannelIds: { string },
	enabled: boolean,
	mode: number,
}

return GuildOnboarding.Interface
