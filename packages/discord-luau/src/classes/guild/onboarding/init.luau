local construct = require("@util/construct")

local GuildOnboardingPrompt = require("prompt")

local CacheType = require("@enums/cacheType")

--[=[
	@class Objects.GuildOnboarding

	The `GuildOnboarding` class provides a way for developers to interact with a Guild Onboarding.
]=]

--[=[
	@prop guildId string
	@within Objects.GuildOnboarding
]=]

--[=[
	@prop prompts { Objects.GuildOnboardingPrompt }
	@within Objects.GuildOnboarding
]=]

--[=[
	@prop defaultChannelIds { string }
	@within Objects.GuildOnboarding
]=]

--[=[
	@prop enabled boolean
	@within Objects.GuildOnboarding
]=]

--[=[
	@prop mode number
	@within Objects.GuildOnboarding
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
		return construct({
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
