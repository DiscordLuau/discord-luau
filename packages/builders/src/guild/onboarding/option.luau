--[=[
	@class Builders.Guild.OnboardingOption
	@__index Prototype

	Implementation of discords Option object as a Luau builder.	

	https://discord.com/developers/docs/resources/guild#guild-onboarding-object-prompt-option-structure
]=]

--[=[
	@prop channelIds {string}
	@within Builders.Guild.OnboardingOption
	Array of channel IDs that are associated with this option.
]=]

--[=[
	@prop roleIds {string}
	@within Builders.Guild.OnboardingOption
	Array of role IDs that are associated with this option.
]=]

--[=[
	@prop emojiId string?
	@within Builders.Guild.OnboardingOption
	The ID of the emoji used for this option.
]=]

--[=[
	@prop emojiName string?
	@within Builders.Guild.OnboardingOption
	The name of the emoji used for this option.
]=]

--[=[
	@prop emojiAnimated boolean?
	@within Builders.Guild.OnboardingOption
	Whether the emoji used for this option is animated.
]=]

--[=[
	@prop title string
	@within Builders.Guild.OnboardingOption
	The title displayed for this option.
]=]

--[=[
	@prop description string?
	@within Builders.Guild.OnboardingOption
	The description displayed for this option.
]=]

local Option = {}

Option.Prototype = {}
Option.Interface = {}

--[=[
	@within Builders.Guild.OnboardingOption

	Add a Channel to this option
]=]
function Option.Prototype.addChannelId(self: Option, channelId: string): Option
	table.insert(self.channelIds, channelId)

	return self
end

--[=[
	@within Builders.Guild.OnboardingOption

	Add a Role to this option
]=]
function Option.Prototype.addRoleId(self: Option, roleId: string): Option
	table.insert(self.roleIds, roleId)

	return self
end

--[=[
	@within Builders.Guild.OnboardingOption

	Sets the emoji of this option.
]=]
function Option.Prototype.setEmoji(self: Option, emojiId: string, emojiName: string, isAnimated: boolean?): Option
	self.emojiId = emojiId
	self.emojiName = emojiName
	self.emojiAnimated = isAnimated

	return self
end

--[=[
	@within Builders.Guild.OnboardingOption

	Sets the title of this option.
]=]
function Option.Prototype.setTitle(self: Option, title: string): Option
	assert(#title >= 1, "title must be at least 1 character")
	assert(#title <= 50, "title must be at most 50 characters")

	self.title = title

	return self
end

--[=[
	@within Builders.Guild.OnboardingOption

	Sets the description of this option.
]=]
function Option.Prototype.setDescription(self: Option, description: string): Option
	assert(#description >= 1, "description must be at least 1 character")
	assert(#description <= 100, "description must be at most 100 characters")

	self.description = description

	return self
end

--[=[
	@within Builders.Guild.OnboardingOption

	Responsible for building the OptionObject JSON that can be parsed by the Discord API.
]=]
function Option.Prototype.build(self: Option): JSON
	assert(self.title, "title must be set before building an option")

	return {
		channel_ids = #self.channelIds > 0 and self.channelIds or nil,
		role_ids = #self.roleIds > 0 and self.roleIds or nil,
		emoji_id = self.emojiId,
		emoji_name = self.emojiName,
		emoji_animated = self.emojiAnimated,
		title = self.title,
		description = self.description,

		emoji = nil,
		id = nil,
	}
end

--[=[
	@within Builders.Guild.OnboardingOption

	Responsible for creating a new Option.
]=]
function Option.Interface.new(resource: {
	channelIds: { string }?,
	roleIds: { string }?,
	emojiId: string?,
	emojiName: string?,
	emojiAnimated: boolean?,
	title: string?,
	description: string?,
}?): Option
	local self = setmetatable(
		{
			channelIds = {},

			roleIds = {},
		} :: Option,
		{
			__index = Option.Prototype,
		}
	)

	if resource then
		if resource.channelIds then
			for _, channelId in resource.channelIds do
				self:addChannelId(channelId)
			end
		end

		if resource.roleIds then
			for _, channelId in resource.roleIds do
				self:addRoleId(channelId)
			end
		end

		if resource.emojiId then
			assert(resource.emojiName, `Expected 'emojiName' with 'emojiId'`)

			self:setEmoji(resource.emojiId, resource.emojiName, resource.emojiAnimated)
		end

		if resource.title then
			self:setTitle(resource.title)
		end

		if resource.description then
			self:setDescription(resource.description)
		end
	end

	return self
end

export type Option = typeof(Option.Prototype) & {
	channelIds: { string },
	roleIds: { string },
	emojiId: string?,
	emojiName: string?,
	emojiAnimated: boolean?,
	title: string,
	description: string?,
}

export type JSON = typeof(Option.Prototype.build(nil :: any))

return Option.Interface
