--[[
	Forum Behaviour, responsible for implementing the various properties, and methods for a forum thread channel.
]]

local apiTypes = require("@api-types/apiTypes")
local channelTypes = require("@api-types/channel")

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

	class.defaultSortOrder = channelTypes.ForumSortOrder[channelData.default_sort_order]
	class.defaultForumLayout = channelTypes.ForumLayout[channelData.default_forum_layout]
end

function ForumBehaviour.Interface.inheritMethods(class: any)
	for key, value in ForumBehaviour.Prototype do
		class[key] = value
	end
end

export type ForumBehaviourMethods = typeof(ForumBehaviour.Prototype)
export type ForumBehaviourProperties = {
	availableTags: { forumTag.ForumTag },
	defaultReaction: defaultReaction.DefaultReaction?,
	appliedTags: { apiTypes.Snowflake },
	defaultSortOrder: channelTypes.ForumSortOrder,
	defaultForumLayout: channelTypes.ForumLayout,
}

export type ForumBehaviour = ForumBehaviourMethods & ForumBehaviourProperties

return ForumBehaviour.Interface
