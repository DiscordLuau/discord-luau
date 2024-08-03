--[[
	Implementation of a discord forum tag object as a luau builder.	

	https://discord.com/developers/docs/resources/channel#forum-tag-object
]]

local apiTypes = require("@api-types/apiTypes")

local validateKebabCase = require("@utils/validateKebabCase")

local ForumTagBuilder = {}

ForumTagBuilder.Prototype = {}
ForumTagBuilder.Interface = {}

--[[
	Sets either the id of a guilds custom emoji, or a unicode character of an emoji.
]]
function ForumTagBuilder.Prototype.setEmoji(
	self: ForumTagBuilder,
	emojiId: string?,
	emojiName: string?
): ForumTagBuilder
	self.emojiId = emojiId
	self.emojiName = emojiName

	return self
end

--[[
	Sets whether this tag can only be added to or removed from threads by a member with the MANAGE_THREADS permission
]]
function ForumTagBuilder.Prototype.setModerated(self: ForumTagBuilder, isModerated: boolean): ForumTagBuilder
	self.moderated = isModerated

	return self
end

--[[
	Set the name of this Forum Tag.
]]
function ForumTagBuilder.Prototype.setName(self: ForumTagBuilder, tagName: string): ForumTagBuilder
	assert(#tagName <= 20, `Tag name must be less than 20 characters.`)
	assert(#tagName > 0, `Tag name must be more than 0 characters.`)

	assert(validateKebabCase(tagName), `Tag name must be kebab-case.`)

	self.name = tagName

	return self
end

--[[
	Responsible for buillding the forum tag object that the Discord API can understand.
]]
function ForumTagBuilder.Prototype.build(self: ForumTagBuilder): apiTypes.ForumTagObject
	return {
		id = self.id,
		name = self.name,
		moderated = self.moderated,
		emoji_id = self.emojiId,
		emoji_name = self.emojiName,
	}
end

--[[
	Constructs a new tag builder.

	```lua
	local tag = ForumTagBuilder.new("tag-name")
	:setModerated(true)	
	:build()
	```
]]
function ForumTagBuilder.Interface.new(resource: {
	tagName: string,
	emoji: {
		name: string,
		id: apiTypes.Snowflake,
	}?,
}): ForumTagBuilder
	local self = setmetatable(
		{
			name = resource.tagName,
			moderated = true,

			emojiId = resource.emoji and resource.emoji.id,
			emojiName = resource.emoji and resource.emoji.name,
		} :: ForumTagBuilder,
		{ __index = ForumTagBuilder.Prototype }
	)

	return self
end

--[[
	Enables us to construct a Tag Builder object from an existing tag object, used when modifying forum tags.
]]
function ForumTagBuilder.Interface.from(resource: {
	tagId: apiTypes.Snowflake,
	tagName: string,
	emoji: {
		name: string,
		id: apiTypes.Snowflake,
	}?,
}): ForumTagBuilder
	local self = ForumTagBuilder.Interface.new(resource)

	self.id = resource.tagId

	return self
end

export type ForumTagBuilder = typeof(ForumTagBuilder.Prototype) & {
	emojiId: apiTypes.Snowflake?,
	emojiName: string?,
	id: apiTypes.Snowflake?,

	moderated: boolean,
	name: string,
}

return ForumTagBuilder.Interface
