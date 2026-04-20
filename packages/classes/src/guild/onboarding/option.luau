--[=[
	@class Classes.OnboardingOption
	@__index Prototype

	Implementation of the Discord Option class in Luau

	https://discord.com/developers/docs/resources/guild#guild-onboarding-object-option-option-structure
]=]

--[=[
	@prop id string?
	@within Classes.OnboardingOption
	The unique identifier of this option
]=]

--[=[
	@prop channelIds {string}
	@within Classes.OnboardingOption
	Array of channel IDs that will be added to the member when this option is selected
]=]

--[=[
	@prop roleIds {string}
	@within Classes.OnboardingOption
	Array of role IDs that will be added to the member when this option is selected
]=]

--[=[
	@prop emoji Classes.Emoji?
	@within Classes.OnboardingOption
	The emoji displayed alongside this option
]=]

--[=[
	@prop title string?
	@within Classes.OnboardingOption
	The title of this option that will be displayed to users
]=]

--[=[
	@prop description string?
	@within Classes.OnboardingOption
	The description of this option that will be displayed to users
]=]

local apiTypes = require("../../../luau_packages/api_types")

local emoji = require("../../emoji")

local Option = {}

Option.Interface = {}
Option.Prototype = {}

--[=[
	@within Classes.OnboardingOption
	@private

	Responsible for syncing data to this option object. This is typically called by the API when this object is
	created or updated.
]=]
function Option.Prototype.sync(self: Option, optionData: apiTypes.PromptOptionObject)
	self.id = optionData.id

	self.channelIds = optionData.channel_ids

	self.roleIds = optionData.role_ids

	self.emoji = optionData.emoji and emoji.new(optionData.emoji)

	self.title = optionData.title

	self.description = optionData.description
end

--[=[
	@within Classes.OnboardingOption
	@private

	Responsible for constructing this class.
]=]
function Option.Interface.new(optionData: apiTypes.PromptOptionObject): Option
	local self = setmetatable({} :: Option, { __index = Option.Prototype })

	self:sync(optionData)

	return self
end

export type Option = typeof(Option.Prototype) & {
	id: apiTypes.Snowflake?,
	channelIds: { apiTypes.Snowflake },
	roleIds: { apiTypes.Snowflake },
	emoji: emoji.Emoji?,
	title: string?,
	description: string?,
}

return Option.Interface
