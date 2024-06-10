local Construct = require("@Utils/Construct")
local Enumerate = require("@Utils/Enumerate")

local Resolvable = require("@Network/Resolvable")

local OnboardingPromptOptionBuilder = require("@Builders/OnboardingPromptOptionBuilder")

local ResolvableType = require("@Enums/ResolvableType")

--[=[
	@class Builders.OnboardingPromptBuilder

	OnboardingPromptBuilder allows you to build onboarding for discord guilds.

	Usage:
	```lua
	local DiscordLuau = require("../Submodules/DiscordLuau")

	local OnboardingPromptBuilder = DiscordLuau.OnboardingPromptBuilder.new()
		:setType(DiscordLuau.OnboardingPromptBuilder.Type.Dropdown)
		:addOption(
			DiscordLuau.OnboardingPromptOptionBuilder.new()
				:setTitle("option-name")
				:setDescription("Option Description!")
		)
	```
]=]
local OnboardingPromptBuilder = {}

OnboardingPromptBuilder.Interface = {}
OnboardingPromptBuilder.Prototype = {}

OnboardingPromptBuilder.Prototype.type = "OnboardingPromptBuilder"

--[=[
	@prop Type table
	@within Builders.OnboardingPromptBuilder

	An enumeration of prompt types

	- MultipleChoice: 0
	- Dropdown: 1
]=]
OnboardingPromptBuilder.Interface.Type = Enumerate.new({
	MultipleChoice = 0,
	Dropdown = 1,
})

--[=[
	Set the type of the Onboarding Prompt builder
	
	@method setType
	@param type number
	@within Builders.OnboardingPromptBuilder
	@return Builders.OnboardingPromptBuilder
]=]
function OnboardingPromptBuilder.Prototype.setType(self: OnboardingPromptBuilder, type: number)
	OnboardingPromptBuilder.Interface.Type:Assert(type)

	self.promptType = type

	return self
end

--[=[
	Adds an option to the Onboarding prompt builder.
	
	@method addOption
	@param option Builders.OnboardingPromptOptionBuilder
	@within Builders.OnboardingPromptBuilder
	@return Builders.OnboardingPromptBuilder
]=]
function OnboardingPromptBuilder.Prototype.addOption(
	self: OnboardingPromptBuilder,
	option: OnboardingPromptOptionBuilder.OnboardingPromptOptionBuilder
)
	table.insert(self.options, option)

	return self
end

--[=[
	Sets the title of the onboarding prompt builder
	
	@method setTitle
	@param title string
	@within Builders.OnboardingPromptBuilder
	@return Builders.OnboardingPromptBuilder
]=]
function OnboardingPromptBuilder.Prototype.setTitle(self: OnboardingPromptBuilder, title: string)
	self.title = title

	return self
end

--[=[
	Indicates whether users are limited to selecting one option for the prompt
	
	@method setSingleSelection
	@param isSingleSelection boolean
	@within Builders.OnboardingPromptBuilder
	@return Builders.OnboardingPromptBuilder
]=]
function OnboardingPromptBuilder.Prototype.setSingleSelection(self: OnboardingPromptBuilder, isSingleSelection: boolean)
	self.singleSelect = isSingleSelection

	return self
end

--[=[
	Indicates whether the prompt is required before a user completes the onboarding flow
	
	@method setRequired
	@param isRequired boolean
	@within Builders.OnboardingPromptBuilder
	@return Builders.OnboardingPromptBuilder
]=]
function OnboardingPromptBuilder.Prototype.setRequired(self: OnboardingPromptBuilder, isRequired: boolean)
	self.required = isRequired

	return self
end

--[=[
	Indicates whether the prompt is present in the onboarding flow. If false, the prompt will only appear in the Channels & Roles tab
	
	@method setIsOnboarding
	@param isInOnboarding boolean
	@within Builders.OnboardingPromptBuilder
	@return Builders.OnboardingPromptBuilder
]=]
function OnboardingPromptBuilder.Prototype.setIsOnboarding(self: OnboardingPromptBuilder, isInOnboarding: boolean)
	self.inOnboarding = isInOnboarding

	return self
end

--[=[
	Converts the message to a JSON object that can be sent to the Discord API.
	
	@method toPayloadObject
	@within Builders.OnboardingPromptBuilder
	@return Network.Resolvable
]=]
function OnboardingPromptBuilder.Prototype.toPayloadObject(self: OnboardingPromptBuilder): Resolvable.Resolvable
	local options = {}

	for index, option in self.options do
		options[index] = option:toPayloadObject():resolve()
	end

	return Resolvable.new(ResolvableType.JSON, {
		type = self.promptType,
		title = self.title,
		single_select = self.singleSelect,
		required = self.required,
		in_onboarding = self.inOnboarding,

		options = #options > 0 and options or nil,
	})
end

--[=[
	Creates a new instance of OnboardingPromptBuilder.
	
	@function new
	@within Builders.OnboardingPromptBuilder
	@return Builders.OnboardingPromptBuilder
]=]
function OnboardingPromptBuilder.Interface.new()
	return (Construct({
		options = {},
	}, OnboardingPromptBuilder.Prototype) :: unknown) :: OnboardingPromptBuilder
end

export type OnboardingPromptBuilder = typeof(OnboardingPromptBuilder.Prototype) & {
	promptType: number,
	title: string,
	singleSelect: boolean,
	required: boolean,
	inOnboarding: boolean,

	options: { OnboardingPromptOptionBuilder.OnboardingPromptOptionBuilder },
}

return OnboardingPromptBuilder.Interface
