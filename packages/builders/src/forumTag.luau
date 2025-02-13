--[[
	Implementation of a discord forum tag object as a luau builder.	

	https://discord.com/developers/docs/resources/channel#forum-tag-object
]]

local apiTypes = require("../lune_packages/api_types")

local util = require("../lune_packages/util")

local ForumTag = {}

ForumTag.Prototype = {}
ForumTag.Interface = {}

--[[
	Sets either the id of a guilds custom emoji, or a unicode character of an emoji.
]]
function ForumTag.Prototype.setEmoji(self: ForumTag, emojiId: string?, emojiName: string?): ForumTag
	self.emojiId = emojiId
	self.emojiName = emojiName

	return self
end

--[[
	Sets whether this tag can only be added to or removed from threads by a member with the MANAGE_THREADS permission
]]
function ForumTag.Prototype.setModerated(self: ForumTag, isModerated: boolean): ForumTag
	self.moderated = isModerated

	return self
end

--[[
	Set the name of this Forum Tag.
]]
function ForumTag.Prototype.setName(self: ForumTag, tagName: string): ForumTag
	assert(#tagName <= 20, `Tag name must be less than 20 characters.`)
	assert(#tagName > 0, `Tag name must be more than 0 characters.`)

	assert(util.validateKebabCase(tagName), `Tag name must be kebab-case.`)

	self.name = tagName

	return self
end

--[[
	Responsible for buillding the forum tag object that the Discord API can understand.
]]
function ForumTag.Prototype.build(self: ForumTag): JSON
	return {
		name = self.name,
		moderated = self.moderated,
		emoji_id = self.emojiId,
		emoji_name = self.emojiName,
	} :: apiTypes.ForumTagObject
end

--[[
	Constructs a new tag builder.

	```lua
	local tag = ForumTag.new("tag-name")
	:setModerated(true)	
	:build()
	```
]]
function ForumTag.Interface.new(resource: {
	tagName: string,
	emoji: {
		name: string,
		id: apiTypes.Snowflake,
	}?,
}): ForumTag
	local self = setmetatable(
		{
			name = resource.tagName,
			moderated = true,

			emojiId = resource.emoji and resource.emoji.id,
			emojiName = resource.emoji and resource.emoji.name,
		} :: ForumTag,
		{ __index = ForumTag.Prototype }
	)

	return self
end

--[[
	Enables us to construct a Tag Builder object from an existing tag object, used when modifying forum tags.
]]
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
