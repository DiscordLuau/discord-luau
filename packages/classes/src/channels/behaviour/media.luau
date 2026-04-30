--[=[
	@class Classes.Channels.MediaBehaviour
	@__index Prototype

	Media Behaviour, responsible for implementing the various properties, and methods for a media thread channel.
]=]

--[=[
	@prop availableTags { Classes.Channels.ForumTag }
	@within Classes.Channels.MediaBehaviour
	The tags that can be applied to posts in this media channel.
]=]

--[=[
	@prop defaultReaction Classes.Channels.DefaultReaction?
	@within Classes.Channels.MediaBehaviour
	The default reaction that will be added to new posts in this media channel.
]=]

--[=[
	@prop defaultForumLayout string
	@within Classes.Channels.MediaBehaviour
	The default layout for posts in this media channel.
]=]

--[=[
	@prop appliedTags { string }
	@within Classes.Channels.MediaBehaviour
	The tags currently applied to this media channel.
]=]

--[=[
	@prop defaultSortOrder string
	@within Classes.Channels.MediaBehaviour
	The default sort order for posts in this media channel.
]=]

local apiTypes = require("../../../luau_packages/api_types")
local future = require("../../../luau_packages/future")
local rest = require("../../../luau_packages/rest")
local state = require("../../../luau_packages/state")
local builders = require("../../../luau_packages/builders")

local forumTag = require("../forumTag")
local defaultReaction = require("../defaultReaction")

local MediaBehaviour = {}

MediaBehaviour.Interface = {}
MediaBehaviour.Prototype = {}

--[=[
	@within Classes.Channels.MediaBehaviour
	@private

	Creates a new forum post (thread) in the channel. Returns the ID of the created thread.
	
	Example usage:
	
	local builder = builders.forumMediaJSON.new()
		:setName("My Thread")
		:setContent("First post!")
	
	channel:createPostAsync(builder:build()):await()
]=]
function MediaBehaviour.Prototype.createPostAsync<T>(self: Channel<T>, post: builders.forumMediaJSON, reason: string?)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.channel.startThreadInForumOrMediaChannelAsync(request, self.id, post, reason):await()

		assert(response:isOk(), `{response:unwrapErr()}`)

		return response:unwrapOk().id :: any
	end) :: future.FutureLike<string, apiTypes.Snowflake>
end

--[=[
	@within Classes.Channels.MediaBehaviour
	@private
]=]
function MediaBehaviour.Interface.inheritProperties(class: any, channelData: apiTypes.ChannelObject)
	local forumTagArray = {}

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

--[=[
	@within Classes.Channels.MediaBehaviour
	@private
]=]
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
