--[=[
	@class Classes.Guild.OnboardingPrompt
	@__index Prototype

	Implementation of the Discord Prompt class in Luau

	https://discord.com/developers/docs/resources/guild#guild-prompt-object-prompt-prompt-structure
]=]

--[=[
	@prop id string
	@within Classes.Guild.OnboardingPrompt

	The unique identifier for this prompt
]=]

--[=[
	@prop type apiTypes.OnboardingPromptType
	@within Classes.Guild.OnboardingPrompt

	The type of prompt this is, determines how it is displayed to users
]=]

--[=[
	@prop options { Classes.Option }
	@within Classes.Guild.OnboardingPrompt

	Array of options that users can select from this prompt
]=]

--[=[
	@prop title string?
	@within Classes.Guild.OnboardingPrompt

	The title shown to users when displaying this prompt
]=]

--[=[
	@prop singleSelect boolean?
	@within Classes.Guild.OnboardingPrompt

	Whether users can only select one option from this prompt
]=]

--[=[
	@prop required boolean?
	@within Classes.Guild.OnboardingPrompt

	Whether this prompt is required to be answered by users
]=]

--[=[
	@prop inOnboarding boolean?
	@within Classes.Guild.OnboardingPrompt

	Whether this prompt is shown during the onboarding flow
]=]

local apiTypes = require("../../../luau_packages/api_types")

local option = require("./option")

local Prompt = {}

Prompt.Interface = {}
Prompt.Prototype = {}

--[=[
	@within Classes.Guild.OnboardingPrompt
	@private

	Responsible for syncing data to this prompt object. This is typically called by the API when this object is
	created or updated.
]=]
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

--[=[
	@within Classes.Guild.OnboardingPrompt
	@private

	Responsible for constructing this class.
]=]
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
