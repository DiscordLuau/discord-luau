--[=[
	@class Builders.Channel.ForumTag
	@__index Prototype

	Implementation of a discord forum tag object as a luau builder.	

	https://discord.com/developers/docs/resources/channel#forum-tag-object
]=]

--[=[
	@prop name string
	@within Builders.Channel.ForumTag
	The name of the tag that is displayed.
]=]

--[=[
	@prop moderated boolean
	@within Builders.Channel.ForumTag
	Whether this tag can only be added to or removed from threads by a member with the MANAGE_THREADS permission.
]=]

--[=[
	@prop emojiId string?
	@within Builders.Channel.ForumTag
	The id of a guild's custom emoji.
]=]

--[=[
	@prop emojiName string?
	@within Builders.Channel.ForumTag
	The unicode character of the emoji.
]=]

--[=[
	@prop id string?
	@within Builders.Channel.ForumTag
	The id of the tag.
]=]

local apiTypes = require("../luau_packages/api_types")

local util = require("../luau_packages/util")

local ForumTag = {}

ForumTag.Prototype = {}
ForumTag.Interface = {}

--[=[
	@within Builders.Channel.ForumTag

	Sets either the id of a guilds custom emoji, or a unicode character of an emoji.
]=]
function ForumTag.Prototype.setEmoji(self: ForumTag, emojiId: string?, emojiName: string?): ForumTag
	self.emojiId = emojiId
	self.emojiName = emojiName

	return self
end

--[=[
	@within Builders.Channel.ForumTag

	Sets whether this tag can only be added to or removed from threads by a member with the MANAGE_THREADS permission
]=]
function ForumTag.Prototype.setModerated(self: ForumTag, isModerated: boolean): ForumTag
	self.moderated = isModerated

	return self
end

--[=[
	@within Builders.Channel.ForumTag

	Set the name of this Forum Tag.
]=]
function ForumTag.Prototype.setName(self: ForumTag, tagName: string): ForumTag
	assert(#tagName <= 20, `Tag name must be less than 20 characters.`)
	assert(#tagName > 0, `Tag name must be more than 0 characters.`)

	assert(util.validateKebabCase(tagName), `Tag name must be kebab-case.`)

	self.name = tagName

	return self
end

--[=[
	@within Builders.Channel.ForumTag

	Responsible for buillding the forum tag object that the Discord API can understand.
]=]
function ForumTag.Prototype.build(self: ForumTag): JSON
	return {
		name = self.name,
		moderated = self.moderated,
		emoji_id = self.emojiId,
		emoji_name = self.emojiName,
	} :: apiTypes.ForumTagObject
end

--[=[
	@within Builders.Channel.ForumTag

	Constructs a new tag builder.
	
	```luau
	local tag = ForumTag.new("tag-name")
		:setModerated(true)	
		:build()
	```	
]=]
function ForumTag.Interface.new(resource: {
	tagName: string,
	emoji: {
		name: string,
		id: apiTypes.Snowflake,
	}?,
}): ForumTag
	local self = setmetatable(
		{
			name = nil,

			moderated = nil,

			emojiId = nil,

			emojiName = nil,
		} :: ForumTag,
		{ __index = ForumTag.Prototype }
	)

	if resource then
		if resource.emoji then
			self:setEmoji(resource.emoji.id, resource.emoji.name)
		end

		if resource.tagName then
			self:setName(resource.tagName)
		end
	end

	return self
end

--[=[
	@within Builders.Channel.ForumTag

	Enables us to construct a Tag Builder object from an existing tag object, used when modifying forum tags.
]=]
function ForumTag.Interface.fromId(resource: {
	tagId: apiTypes.Snowflake,
	tagName: string,
	emoji: {
		name: string,
		id: apiTypes.Snowflake,
	}?,
}): ForumTag
	local self = ForumTag.Interface.new(resource)

	self.id = resource.tagId

	return self
end

export type ForumTag = typeof(ForumTag.Prototype) & {
	emojiId: apiTypes.Snowflake?,
	emojiName: string?,
	id: apiTypes.Snowflake?,

	moderated: boolean,
	name: string,
}

export type JSON = typeof(ForumTag.Prototype.build(nil :: any))

return ForumTag.Interface
