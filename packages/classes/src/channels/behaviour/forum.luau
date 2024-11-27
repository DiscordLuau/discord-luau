--[[
	Forum Behaviour, responsible for implementing the various properties, and methods for a forum thread channel.
]]

local future = require("@vendor/future")

local apiTypes = require("@api-types/apiTypes")
local channelTypes = require("@api-types/channel")

local channelRest = require("@rest/channel")

local forumTag = require("@classes/channels/forumTag")
local defaultReaction = require("@classes/channels/defaultReaction")
local state = require("@classes/state")

local forumMediaBuilder = require("@builders/thread/forumMedia")

local ForumBehaviour = {}

ForumBehaviour.Interface = {}
ForumBehaviour.Prototype = {}

--[[
 	Creates a new forum post (thread) in the channel. Returns the ID of the created thread.
 	
 	Example usage:
 	
 	local builder = forumMediaBuilder.new()
 		:setName("My Thread")
 		:setContent("First post!")
 	
 	channel:createPostAsync(builder:build()):await()
]]
function ForumBehaviour.Prototype.createPostAsync<T>(
	self: Channel<T>,
	post: forumMediaBuilder.JSON,
	reason: string?
): future.Future<string>
	return future.new(function()
		local request = self.state.rest:newRequest()

		local status, response =
			channelRest.startThreadInForumOrMediaChannelAsync(request, self.id, post, reason):await()

		assert(status == "Fulfilled", tostring(response))

		return response.id
	end)
end

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

type Channel<T> = T & ForumBehaviour & {
	state: state.State,
	id: string,

	sync: (...any) -> (),
}

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
