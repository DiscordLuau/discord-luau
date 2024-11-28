--[[
	Implementation of the Discord Onboarding class in Luau

	https://discord.com/developers/docs/resources/guild#guild-onboarding-object
]]

local apiTypes = require("../../../lune_packages/api_types")

local prompt = require("./prompt")

local Onboarding = {}

Onboarding.Interface = {}
Onboarding.Prototype = {}

function Onboarding.Prototype.sync(self: Onboarding, onboardingData: apiTypes.GuildOnboardingObject)
	local promptArray = {}

	for _, promptData in onboardingData.prompts do
		table.insert(promptArray, prompt.new(promptData))
	end

	self.guildId = onboardingData.guild_id
	self.prompts = promptArray
	self.defaultChannelIds = onboardingData.default_channel_ids
	self.enabled = onboardingData.enabled
	self.mode = apiTypes.guild.OnboardingMode[onboardingData.mode]
end

function Onboarding.Interface.new(onboardingData: apiTypes.GuildOnboardingObject): Onboarding
	local self = setmetatable({} :: Onboarding, { __index = Onboarding.Prototype })

	self:sync(onboardingData)

	return self
end

export type Onboarding = typeof(Onboarding.Prototype) & {
	guildId: apiTypes.Snowflake?,
	prompts: { prompt.Prompt },
	defaultChannelIds: { apiTypes.Snowflake },
	enabled: boolean,
	mode: apiTypes.OnboardingMode,
}

return Onboarding.Interface
