--[[
	Media Behaviour, responsible for implementing the various properties, and methods for a media thread channel.
]]

local apiTypes = require("../../../lune_packages/api_types")
local async = require("../../../lune_packages/async")
local rest = require("../../../lune_packages/rest")
local state = require("../../../lune_packages/state")
local builders = require("../../../lune_packages/builders")

local forumTag = require("../forumTag")
local defaultReaction = require("../defaultReaction")

local MediaBehaviour = {}

MediaBehaviour.Interface = {}
MediaBehaviour.Prototype = {}

--[[
 	Creates a new forum post (thread) in the channel. Returns the ID of the created thread.
 	
 	Example usage:
 	
 	local builder = builders.forumMediaJSON.new()
 		:setName("My Thread")
 		:setContent("First post!")
 	
 	channel:createPostAsync(builder:build()):await()
]]
function MediaBehaviour.Prototype.createPostAsync<T>(
	self: Channel<T>,
	post: builders.forumMediaJSON,
	reason: string?
): async.Async<string>
	return async.new(function()
		local request = self.state.rest:newRequest()

		local status, response =
			rest.channel.startThreadInForumOrMediaChannelAsync(request, self.id, post, reason):await()

		assert(status == "Fulfilled", tostring(response))

		return response.id
	end)
end

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

	class.defaultSortOrder = apiTypes.channel.MediaSortOrder[channelData.default_sort_order]
end

function MediaBehaviour.Interface.inheritMethods(class: any)
	for key, value in MediaBehaviour.Prototype do
		class[key] = value
	end
end

type Channel<T> = T & MediaBehaviour & {
	state: state.State,
	id: string,

	sync: (...any) -> (),
}

export type MediaBehaviourMethods = typeof(MediaBehaviour.Prototype)
export type MediaBehaviourProperties = {
	availableTags: { forumTag.ForumTag },
	defaultReaction: defaultReaction.DefaultReaction?,
	appliedTags: { apiTypes.Snowflake },
	defaultForumLayout: apiTypes.MediaSortOrder,
}

export type MediaBehaviour = MediaBehaviourMethods & MediaBehaviourProperties

return MediaBehaviour.Interface
