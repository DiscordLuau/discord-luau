--[[
	Implementation of the Discord Prompt class in Luau

	https://discord.com/developers/docs/resources/guild#guild-prompt-object-prompt-prompt-structure
]]

local apiTypes = require("../../../lune_packages/api_types")

local option = require("./option")

local Prompt = {}

Prompt.Interface = {}
Prompt.Prototype = {}

function Prompt.Prototype.sync(self: Prompt, promptData: apiTypes.OnboardingPromptObject)
	local optionsArray = {}

	for _, optionData in promptData.options do
		table.insert(optionsArray, option.new(optionData))
	end

	self.id = promptData.id
	self.type = apiTypes.guild.OnboardingPromptType[promptData.type]
	self.options = optionsArray
	self.title = promptData.title
	self.singleSelect = promptData.single_select
	self.required = promptData.required
	self.inOnboarding = promptData.in_onboarding
end

function Prompt.Interface.new(promptData: apiTypes.OnboardingPromptObject): Prompt
	local self = setmetatable({} :: Prompt, { __index = Prompt.Prototype })

	self:sync(promptData)

	return self
end

export type Prompt = typeof(Prompt.Prototype) & {
	id: apiTypes.Snowflake?,
	type: apiTypes.OnboardingPromptType,
	options: { option.Option },
	title: string?,
	singleSelect: boolean?,
	required: boolean?,
	inOnboarding: boolean?,
}

return Prompt.Interface
