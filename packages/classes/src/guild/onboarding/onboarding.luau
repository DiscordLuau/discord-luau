--[=[
	@class Classes.Guild.Onboarding
	@__index Prototype

	Implementation of the Discord Onboarding class in Luau

	https://discord.com/developers/docs/resources/guild#guild-onboarding-object
]=]

--[=[
	@prop guildId string
	@within Classes.Guild.Onboarding
	The unique identifier of the guild this onboarding object belongs to
]=]

--[=[
	@prop prompts { Classes.Guild.OnboardingPrompt }
	@within Classes.Guild.Onboarding
	Array of prompts shown during onboarding and in customize community
]=]

--[=[
	@prop defaultChannelIds { string }
	@within Classes.Guild.Onboarding
	Array of channel IDs that members get opted into automatically
]=]

--[=[
	@prop enabled boolean
	@within Classes.Guild.Onboarding
	Whether onboarding is enabled in the guild
]=]

--[=[
	@prop mode apiTypes.OnboardingMode
	@within Classes.Guild.Onboarding
	Current mode of onboarding, determines what users can see and interact with
]=]

local apiTypes = require("../../../luau_packages/api_types")

local prompt = require("./prompt")

local Onboarding = {}

Onboarding.Interface = {}
Onboarding.Prototype = {}

--[=[
	@within Classes.Guild.Onboarding
	@private

	Responsible for syncing data to this onboarding object. This is typically called by the API when this object is
	created or updated.
]=]
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

--[=[
	@within Classes.Guild.Onboarding
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
