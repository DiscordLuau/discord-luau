--[=[
	@class Classes.Prompt
	@__index Prototype

	Implementation of the Discord Prompt class in Luau

	https://discord.com/developers/docs/resources/guild#guild-prompt-object-prompt-prompt-structure
]=]

local apiTypes = require("../../../lune_packages/api_types")

local option = require("./option")

local Prompt = {}

Prompt.Interface = {}
Prompt.Prototype = {}

--[=[
	@within Classes.Prompt
	@private

	Responsible for syncing data to this prompt object. This is typically called by the API when this object is
	created or updated.
]=]
function Prompt.Prototype.sync(self: Prompt, promptData: apiTypes.OnboardingPromptObject)
	local optionsArray = {}

	for _, optionData in promptData.options do
		table.insert(optionsArray, option.new(optionData))
	end

	--[=[
		@prop id string
		@within Classes.Prompt

		The unique identifier for this prompt
	]=]
	self.id = promptData.id

	--[=[
		@prop type apiTypes.OnboardingPromptType
		@within Classes.Prompt

		The type of prompt this is, determines how it is displayed to users
	]=]
	self.type = apiTypes.guild.OnboardingPromptType[promptData.type]

	--[=[
		@prop options { Classes.Option }
		@within Classes.Prompt

		Array of options that users can select from this prompt
	]=]
	self.options = optionsArray

	--[=[
		@prop title string?
		@within Classes.Prompt

		The title shown to users when displaying this prompt
	]=]
	self.title = promptData.title

	--[=[
		@prop singleSelect boolean?
		@within Classes.Prompt

		Whether users can only select one option from this prompt
	]=]
	self.singleSelect = promptData.single_select

	--[=[
		@prop required boolean?
		@within Classes.Prompt

		Whether this prompt is required to be answered by users
	]=]
	self.required = promptData.required

	--[=[
		@prop inOnboarding boolean?
		@within Classes.Prompt

		Whether this prompt is shown during the onboarding flow
	]=]
	self.inOnboarding = promptData.in_onboarding
end

--[=[
	@within Classes.Prompt
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
