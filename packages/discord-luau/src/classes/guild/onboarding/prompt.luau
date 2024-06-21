local construct = require("@util/construct")

local GuildOnboardingPromptOption = require("option")

local CacheType = require("@enums/cacheType")

--[=[
	@class Objects.GuildOnboardingPrompt

	The `GuildOnboardingPrompt` class provides a way for developers to interact with a guild onboarding prompt.
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
	--[=[
		@prop id string
		@within Objects.GuildOnboardingPrompt
	]=]

	--[=[
		@prop type number
		@within Objects.GuildOnboardingPrompt
	]=]

	--[=[
		@prop options { Objects.GuildOnboardingPromptOption }
		@within Objects.GuildOnboardingPrompt
	]=]

	--[=[
		@prop title string
		@within Objects.GuildOnboardingPrompt
	]=]

	--[=[
		@prop singleSelect boolean
		@within Objects.GuildOnboardingPrompt
	]=]

	--[=[
		@prop required boolean
		@within Objects.GuildOnboardingPrompt
	]=]

	--[=[
		@prop inOboarding boolean
		@within Objects.GuildOnboardingPrompt
	]=]

	local self = discordClient.discordCache:getDataOr(CacheType.OnboardingPrompt, onboardingPromptData.id, function()
		return construct({
			id = onboardingPromptData.id,

			discordClient = discordClient,
		}, discordClient.Prototype)
	end)

	if onboardingPromptData.options then
		for index, value in onboardingPromptData.options do
			onboardingPromptData.options[index] = GuildOnboardingPromptOption.new(discordClient, value)
		end
	end

	for index, value in onboardingPromptData do
		self[index] = value
	end

	return self
end

export type GuildOnboardingPrompt = typeof(GuildOnboardingPrompt.Prototype) & {
	id: string,
	type: number,
	options: { GuildOnboardingPromptOption.GuildOnboardingPromptOption },
	title: string,
	singleSelect: boolean,
	required: boolean,
	inOboarding: boolean,
}

return GuildOnboardingPrompt.Interface
