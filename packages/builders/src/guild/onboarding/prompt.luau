--[[
	Implementation of discords Prompt object as a Luau builder.	

	https://discord.com/developers/docs/resources/guild#guild-onboarding-object-onboarding-prompt-structure
]]

local apiTypes = require("../../../lune_packages/api_types")

local option = require("./option")

local Prompt = {}

Prompt.Prototype = {}
Prompt.Interface = {}

--[[
	Add an Option to this prompt
]]
function Prompt.Prototype.addOption(self: Prompt, option: option.JSON): Prompt
	table.insert(self.options, option)

	return self
end

--[[
	Set the type of prompt.
]]
function Prompt.Prototype.setType(self: Prompt, type: apiTypes.OnboardingPromptType): Prompt
	self.type = type

	return self
end

--[[
	Set the title of this prompt
]]
function Prompt.Prototype.setTitle(self: Prompt, title: string): Prompt
	self.title = title

	return self
end

--[[
	Set weather or not users can select one option, or multiple.
]]
function Prompt.Prototype.setSingleSelect(self: Prompt, singleSelect: boolean): Prompt
	self.singleSelect = singleSelect

	return self
end

--[[
	Set weather this option is required or not.
]]
function Prompt.Prototype.setRequired(self: Prompt, required: boolean): Prompt
	self.required = required

	return self
end

--[[
	Responsible for building the PromptObject JSON that can be parsed by the Discord API.
]]
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

--[[
	Responsible for creating a new Prompt.

	```lua
	
	```
]]
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
