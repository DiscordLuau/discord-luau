--[[
	Implementation of the Discord ForumTag class in Luau

	https://discord.com/developers/docs/resources/channel#forum-tag-object
]]

local apiTypes = require("../../lune_packages/api_types")

local ForumTag = {}

ForumTag.Interface = {}
ForumTag.Prototype = {}

function ForumTag.Prototype.sync(self: ForumTag, forumTagData: apiTypes.ForumTagObject)
	self.id = forumTagData.id
	self.name = forumTagData.name
	self.moderated = forumTagData.moderated
	self.emojiId = forumTagData.emoji_id
	self.emojiName = forumTagData.emoji_name
end

function ForumTag.Interface.new(forumTagData: apiTypes.ForumTagObject): ForumTag
	local self = setmetatable({} :: ForumTag, { __index = ForumTag.Prototype })

	self:sync(forumTagData)

	return self
end

export type ForumTagType = "role" | "member"
export type ForumTag = typeof(ForumTag.Prototype) & {
	id: apiTypes.Snowflake,
	name: string,
	moderated: boolean,
	emojiId: string?,
	emojiName: string?,
}

return ForumTag.Interface
