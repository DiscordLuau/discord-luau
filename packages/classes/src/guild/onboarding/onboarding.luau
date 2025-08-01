--[=[
	@class Classes.Onboarding
	@__index Prototype

	Implementation of the Discord Onboarding class in Luau

	https://discord.com/developers/docs/resources/guild#guild-onboarding-object
]=]

local apiTypes = require("../../../lune_packages/api_types")

local prompt = require("./prompt")

local Onboarding = {}

Onboarding.Interface = {}
Onboarding.Prototype = {}

--[=[
	@within Classes.Onboarding
	@private

	Responsible for syncing data to this onboarding object. This is typically called by the API when this object is
	created or updated.
]=]
function Onboarding.Prototype.sync(self: Onboarding, onboardingData: apiTypes.GuildOnboardingObject)
	local promptArray = {}

	for _, promptData in onboardingData.prompts do
		table.insert(promptArray, prompt.new(promptData))
	end

	--[=[
		@prop guildId string
		@within Classes.Onboarding
		The unique identifier of the guild this onboarding object belongs to
	]=]
	self.guildId = onboardingData.guild_id

	--[=[
		@prop prompts { Classes.Prompt }
		@within Classes.Onboarding
		Array of prompts shown during onboarding and in customize community
	]=]
	self.prompts = promptArray

	--[=[
		@prop defaultChannelIds { string }
		@within Classes.Onboarding
		Array of channel IDs that members get opted into automatically
	]=]
	self.defaultChannelIds = onboardingData.default_channel_ids

	--[=[
		@prop enabled boolean
		@within Classes.Onboarding
		Whether onboarding is enabled in the guild
	]=]
	self.enabled = onboardingData.enabled

	--[=[
		@prop mode apiTypes.OnboardingMode
		@within Classes.Onboarding
		Current mode of onboarding, determines what users can see and interact with
	]=]
	self.mode = apiTypes.guild.OnboardingMode[onboardingData.mode]
end

--[=[
	@within Classes.Onboarding
	@private

	Responsible for constructing this class.
]=]
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
