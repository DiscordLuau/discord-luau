--[=[
	@class Classes.ForumBehaviour
	@__index Prototype

	Implementation of the Discord Forum Behaviour class in Luau. Responsible for implementing the various properties, 
	and methods for a forum thread channel.
]=]

local apiTypes = require("../../../lune_packages/api_types")
local future = require("../../../luau_packages/future")
local rest = require("../../../lune_packages/rest")
local state = require("../../../lune_packages/state")
local builders = require("../../../lune_packages/builders")

local forumTag = require("../forumTag")
local defaultReaction = require("../defaultReaction")

local ForumBehaviour = {}

ForumBehaviour.Interface = {}
ForumBehaviour.Prototype = {}

--[=[
	@within Classes.ForumBehaviour
	@private

	Creates a new forum post (thread) in the channel. Returns the ID of the created thread.
	
	Example usage:
	
	local builder = forumMediaBuilder.new()
		:setName("My Thread")
		:setContent("First post!")
	
	channel:createPostAsync(builder:build()):await()
]=]
function ForumBehaviour.Prototype.createPostAsync<T>(self: Channel<T>, post: builders.forumMediaJSON, reason: string?)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.channel.startThreadInForumOrMediaChannelAsync(request, self.id, post, reason):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().id :: any
	end) :: future.FutureLike<string, apiTypes.Snowflake>
end

--[=[
	@within Classes.ForumBehaviour
	@private
]=]
function ForumBehaviour.Interface.inheritProperties(class: any, channelData: apiTypes.ChannelObject)
	--[=[
		@prop availableTags { Classes.ForumTag }
		@within Classes.ForumBehaviour
		The tags that can be applied to posts in this forum channel.
	]=]
	local forumTagArray = {}

	-- fixme: need to use `next` iterator here to avoid LSP errors.
	for _, forumTagData in next, channelData.available_tags or {} do
		table.insert(forumTagArray, forumTag.new(forumTagData))
	end

	class.availableTags = forumTagArray

	--[=[
		@prop appliedTags { string }
		@within Classes.ForumBehaviour
		The tags currently applied to this forum channel.
	]=]
	class.appliedTags = channelData.applied_tags

	--[=[
		@prop defaultReaction Classes.DefaultReaction?
		@within Classes.ForumBehaviour
		The default reaction that will be added to new posts in this forum channel.
	]=]
	class.defaultReaction = channelData.default_reaction_emoji
		and defaultReaction.new(channelData.default_reaction_emoji)

	--[=[
		@prop defaultSortOrder apiTypes.ForumSortOrder
		@within Classes.ForumBehaviour
		The default sort order for posts in this forum channel.
	]=]
	class.defaultSortOrder = apiTypes.channel.ForumSortOrder[channelData.default_sort_order]

	--[=[
		@prop defaultForumLayout apiTypes.ForumLayout
		@within Classes.ForumBehaviour
		The default layout for posts in this forum channel.
	]=]
	class.defaultForumLayout = apiTypes.channel.ForumLayout[channelData.default_forum_layout]
end

--[=[
	@within Classes.ForumBehaviour
	@private
]=]
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
	defaultSortOrder: apiTypes.ForumSortOrder,
	defaultForumLayout: apiTypes.ForumLayout,
}

export type ForumBehaviour = ForumBehaviourMethods & ForumBehaviourProperties

return ForumBehaviour.Interface
