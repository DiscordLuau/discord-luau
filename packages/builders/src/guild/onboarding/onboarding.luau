--[=[
	@class Builders.Onboarding
	@__index Prototype

	Implementation of discords Onboarding object as a Luau builder.	

	https://discord.com/developers/docs/resources/guild#modify-guild-onboarding-json-params
]=]

local apiTypes = require("../../../lune_packages/api_types")

local prompt = require("./prompt")

local Onboarding = {}

Onboarding.Prototype = {}
Onboarding.Interface = {}

--[=[
	@within Builders.Onboarding

	Add a prompt to this onboarding
]=]
function Onboarding.Prototype.addPrompt(self: Onboarding, prompt: prompt.JSON): Onboarding
	table.insert(self.prompts, prompt)

	return self
end

--[=[
	@within Builders.Onboarding

	Add a default channel to this onboarding
]=]
function Onboarding.Prototype.addDefaultChannelId(self: Onboarding, channelId: string): Onboarding
	table.insert(self.defaultChannelIds, channelId)

	return self
end

--[=[
	@within Builders.Onboarding

	Set weather this onboarding is enabled or not.	
]=]
function Onboarding.Prototype.setEnabled(self: Onboarding, enabled: boolean): Onboarding
	self.enabled = enabled

	return self
end

--[=[
	@within Builders.Onboarding

	Set the mode of this onboarding.
]=]
function Onboarding.Prototype.setMode(self: Onboarding, mode: apiTypes.OnboardingMode): Onboarding
	self.mode = mode

	return self
end

--[=[
	@within Builders.Onboarding

	Responsible for building the OnboardingObject JSON that can be parsed by the Discord API.
]=]
function Onboarding.Prototype.build(self: Onboarding): JSON
	return {
		prompts = self.prompts,
		default_channel_ids = self.defaultChannelIds,
		enabled = self.enabled,
		mode = self.mode,
	}
end

--[=[
	@within Builders.Onboarding

	Responsible for creating a new Onboarding.
]=]
function Onboarding.Interface.new(resource: {
	prompts: { prompt.JSON }?,
	defaultChannelIds: { string }?,
	enabled: boolean?,
	mode: apiTypes.OnboardingMode?,
}?): Onboarding
	local self = setmetatable(
		{
			--[=[
				@prop prompts {Builders.Prompt}
				@within Builders.Onboarding
				Array of prompts shown during onboarding
			]=]
			prompts = {},

			--[=[
				@prop defaultChannelIds {string}
				@within Builders.Onboarding
				Array of channel IDs that members get opted into automatically
			]=]
			defaultChannelIds = {},

			--[=[
				@prop enabled boolean
				@within Builders.Onboarding
				Whether onboarding is enabled in the guild
			]=]

			--[=[
				@prop mode apiTypes.OnboardingMode
				@within Builders.Onboarding
				Current mode of onboarding
			]=]
		} :: Onboarding,
		{
			__index = Onboarding.Prototype,
		}
	)

	if resource then
		if resource.prompts then
			for _, prompt in resource.prompts do
				self:addPrompt(prompt)
			end
		end

		if resource.defaultChannelIds then
			for _, channelId in resource.defaultChannelIds do
				self:addDefaultChannelId(channelId)
			end
		end

		if resource.enabled then
			self:setEnabled(resource.enabled)
		end

		if resource.mode then
			self:setMode(resource.mode)
		end
	end

	return self
end

export type Onboarding = typeof(Onboarding.Prototype) & {
	prompts: { prompt.JSON },
	defaultChannelIds: { string },
	enabled: boolean,
	mode: apiTypes.OnboardingMode,
}

export type JSON = typeof(Onboarding.Prototype.build(nil :: any))

return Onboarding.Interface
