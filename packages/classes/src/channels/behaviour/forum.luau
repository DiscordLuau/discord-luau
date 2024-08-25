local apiTypes = require("@api-types/apiTypes")

local forumTag = require("@classes/channels/forumTag")
local defaultReaction = require("@classes/channels/defaultReaction")

local ForumBehaviour = {}

ForumBehaviour.Interface = {}
ForumBehaviour.Prototype = {}

function ForumBehaviour.Interface.inheritProperties(class: any, channelData: apiTypes.ChannelObject)
	local forumTagArray = {}

	-- fixme: need to use `next` iterator here to avoid LSP errors.
	for _, forumTagData in next, channelData.available_tags or {} do
		table.insert(forumTagArray, forumTag.new(forumTagData))
	end

	class.availableTags = forumTagArray
	class.appliedTags = channelData.applied_tags

	class.defaultReaction = channelData.default_reaction_emoji
		and defaultReaction.new(channelData.default_reaction_emoji)

	class.defaultSortOrder = (
		channelData.default_sort_order == 0 and "LatestActivity"
		or channelData.default_sort_order == 1 and "CreationDate"
	) :: ForumSortOrder

	class.defaultForumLayout = (
		channelData.default_forum_layout == 0 and "NotSet"
		or channelData.default_forum_layout == 1 and "ListView"
		or channelData.default_forum_layout == 2 and "GalleryView"
	) :: ForumLayout
end

function ForumBehaviour.Interface.inheritMethods(class: any)
	for key, value in ForumBehaviour.Prototype do
		class[key] = value
	end
end

export type ForumSortOrder = "LatestActivity" | "CreationDate"
export type ForumLayout = "NotSet" | "ListView" | "GalleryView"

export type ForumBehaviourMethods = typeof(ForumBehaviour.Prototype)
export type ForumBehaviourProperties = {
	availableTags: { forumTag.ForumTag },
	defaultReaction: defaultReaction.DefaultReaction?,
	appliedTags: { apiTypes.Snowflake },
	defaultSortOrder: ForumSortOrder,
	defaultForumLayout: ForumLayout,
}

export type ForumBehaviour = ForumBehaviourMethods & ForumBehaviourProperties

return ForumBehaviour.Interface
