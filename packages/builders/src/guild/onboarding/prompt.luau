--[=[
	@class Builders.Guild.OnboardingPrompt
	@__index Prototype

	Implementation of discords Prompt object as a Luau builder.	

	https://discord.com/developers/docs/resources/guild#guild-onboarding-object-onboarding-prompt-structure
]=]

--[=[
	@prop options { Builders.Message.SelectMenuOption }
	@within Builders.Guild.OnboardingPrompt
	The array of options available within this prompt.
]=]

--[=[
	@prop type apiTypes.OnboardingPromptType
	@within Builders.Guild.OnboardingPrompt
	The type of prompt to display.
]=]

--[=[
	@prop title string
	@within Builders.Guild.OnboardingPrompt
	The title of the prompt to display.
]=]

--[=[
	@prop singleSelect boolean
	@within Builders.Guild.OnboardingPrompt
	Whether users can select only one option or multiple options.
]=]

--[=[
	@prop required boolean
	@within Builders.Guild.OnboardingPrompt
	Whether this prompt is required to be answered or not.
]=]

local apiTypes = require("../../../luau_packages/api_types")

local option = require("./option")

local Prompt = {}

Prompt.Prototype = {}
Prompt.Interface = {}

--[=[
	@within Builders.Guild.OnboardingPrompt

	Add an Option to this prompt
]=]
function Prompt.Prototype.addOption(self: Prompt, option: option.JSON): Prompt
	table.insert(self.options, option)

	return self
end

--[=[
	@within Builders.Guild.OnboardingPrompt

	Set the type of prompt.
]=]
function Prompt.Prototype.setType(self: Prompt, type: apiTypes.OnboardingPromptType): Prompt
	self.type = type

	return self
end

--[=[
	@within Builders.Guild.OnboardingPrompt

	Set the title of this prompt
]=]
function Prompt.Prototype.setTitle(self: Prompt, title: string): Prompt
	self.title = title

	return self
end

--[=[
	@within Builders.Guild.OnboardingPrompt

	Set weather or not users can select one option, or multiple.
]=]
function Prompt.Prototype.setSingleSelect(self: Prompt, singleSelect: boolean): Prompt
	self.singleSelect = singleSelect

	return self
end

--[=[
	@within Builders.Guild.OnboardingPrompt

	Set weather this option is required or not.
]=]
function Prompt.Prototype.setRequired(self: Prompt, required: boolean): Prompt
	self.required = required

	return self
end

--[=[
	@within Builders.Guild.OnboardingPrompt

	Responsible for building the PromptObject JSON that can be parsed by the Discord API.
]=]
function Prompt.Prototype.build(self: Prompt): JSON
	return {
		type = apiTypes.guild.OnboardingPromptType[self.type],
		options = self.options,
		title = self.title,
		single_select = self.singleSelect,
		required = self.required,

		id = nil,
		in_onboarding = nil,
	}
end

--[=[
	@within Builders.Guild.OnboardingPrompt

	Responsible for creating a new Prompt.
]=]
function Prompt.Interface.new(resource: {
	type: apiTypes.OnboardingPromptType?,
	options: { option.JSON }?,
	title: string?,
	singleSelect: boolean?,
	required: boolean?,
}?): Prompt
	local self = setmetatable(
		{
			options = {},

			type = resource and resource.type,

			title = resource and resource.title,

			singleSelect = resource and resource.singleSelect,

			required = resource and resource.required,
		} :: Prompt,
		{
			__index = Prompt.Prototype,
		}
	)

	if resource then
		if resource.type then
			self:setTitle(resource.type)
		end

		if resource.options then
			for _, option in resource.options do
				self:addOption(option)
			end
		end

		if resource.title then
			self:setTitle(resource.title)
		end

		if resource.singleSelect ~= nil then
			self:setSingleSelect(resource.singleSelect)
		end

		if resource.required ~= nil then
			self:setRequired(resource.required)
		end
	end

	return self
end

export type Prompt = typeof(Prompt.Prototype) & {
	type: apiTypes.OnboardingPromptType,
	options: { option.JSON },
	title: string,
	singleSelect: boolean,
	required: boolean,
}

export type JSON = typeof(Prompt.Prototype.build(nil :: any))

return Prompt.Interface
