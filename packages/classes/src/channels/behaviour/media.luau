--[[
	Media Behaviour, responsible for implementing the various properties, and methods for a media thread channel.
]]

local apiTypes = require("@api-types/apiTypes")
local channelTypes = require("@api-types/channel")

local forumTag = require("@classes/channels/forumTag")
local defaultReaction = require("@classes/channels/defaultReaction")

local MediaBehaviour = {}

MediaBehaviour.Interface = {}
MediaBehaviour.Prototype = {}

function MediaBehaviour.Interface.inheritProperties(class: any, channelData: apiTypes.ChannelObject)
	local forumTagArray = {}

	-- fixme: need to use `next` iterator here to avoid LSP errors.
	for _, mediaTagData in next, channelData.available_tags or {} do
		table.insert(forumTagArray, forumTag.new(mediaTagData))
	end

	class.availableTags = forumTagArray

	class.defaultReaction = channelData.default_reaction_emoji
		and defaultReaction.new(channelData.default_reaction_emoji)

	class.defaultForumLayout = channelData.default_forum_layout
	class.appliedTags = channelData.applied_tags

	class.defaultSortOrder = channelTypes.MediaSortOrder[channelData.default_sort_order]
end

function MediaBehaviour.Interface.inheritMethods(class: any)
	for key, value in MediaBehaviour.Prototype do
		class[key] = value
	end
end

export type MediaBehaviourMethods = typeof(MediaBehaviour.Prototype)
export type MediaBehaviourProperties = {
	availableTags: { forumTag.ForumTag },
	defaultReaction: defaultReaction.DefaultReaction?,
	appliedTags: { apiTypes.Snowflake },
	defaultForumLayout: channelTypes.MediaSortOrder,
}

export type MediaBehaviour = MediaBehaviourMethods & MediaBehaviourProperties

return MediaBehaviour.Interface
