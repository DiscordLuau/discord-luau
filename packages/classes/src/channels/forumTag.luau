--[=[
	@class Classes.ForumTag
	@__index Prototype

	Implementation of the Discord ForumTag class in Luau

	https://discord.com/developers/docs/resources/channel#forum-tag-object
]=]

--[=[
	@prop id string
	@within Classes.ForumTag

	The unique identifier for this forum tag
]=]

--[=[
	@prop name string
	@within Classes.ForumTag

	The name of the forum tag
]=]

--[=[
	@prop moderated boolean
	@within Classes.ForumTag

	Whether this tag can only be added to or removed by a moderator
]=]

--[=[
	@prop emojiId string?
	@within Classes.ForumTag

	The id of the emoji used as the tag's icon, if the tag has a custom emoji
]=]

--[=[
	@prop emojiName string?
	@within Classes.ForumTag

	The name of the emoji used as the tag's icon
]=]

local apiTypes = require("../../luau_packages/api_types")

local ForumTag = {}

ForumTag.Interface = {}
ForumTag.Prototype = {}

--[=[
	@within Classes.ForumTag
	@private

	Responsible for syncing data to this forum tag object. This is typically called by the API when this object is
	created or updated.
]=]
function ForumTag.Prototype.sync(self: ForumTag, forumTagData: apiTypes.ForumTagObject)
	self.id = forumTagData.id

	self.name = forumTagData.name

	self.moderated = forumTagData.moderated

	self.emojiId = forumTagData.emoji_id

	self.emojiName = forumTagData.emoji_name
end

--[=[
	@within Classes.ForumTag
	@private

	Responsible for constructing this class.
]=]
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
