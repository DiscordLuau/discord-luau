--[=[
	@class Classes.Forum
	@__index Prototype

	Implementation of the Discord Forum class in Luau

	https://discord.com/developers/docs/resources/channel#channel-object
]=]

local apiTypes = require("../../../lune_packages/api_types")
local state = require("../../../lune_packages/state")

local channelBehaviour = require("../behaviour/channel")
local guildBehaviour = require("../behaviour/guild")
local textBehaviour = require("../behaviour/text")
local threadBehaviour = require("../behaviour/thread")
local forumBehaviour = require("../behaviour/forum")

local Forum = {}

Forum.Interface = {}
Forum.Prototype = {}
Forum.Behaviours = {
	channelBehaviour,
	guildBehaviour,
	threadBehaviour,
	forumBehaviour,
	textBehaviour,
}

--[=[
	@within Classes.Forum
	@private

	Responsible for syncing data to this forum object. This is typically called by the API when this object is
	created or updated.
]=]
function Forum.Prototype.sync(self: Forum, channelData: apiTypes.ChannelObject)
	for _, behaviour in Forum.Behaviours do
		behaviour.inheritMethods(self)
		behaviour.inheritProperties(self, channelData)
	end
end

--[=[
	@within Classes.Forum
	@private

	Responsible for constructing this class.
]=]
function Forum.Interface.new(state: state.State, channelData: apiTypes.ChannelObject): Forum
	local self = setmetatable(
		{
			--[=[
				@prop state Classes.State
				@within Classes.Forum
			]=]
			state = state,
		} :: Forum,
		{ __index = Forum.Prototype }
	)

	self:sync(channelData)

	return self
end

export type Forum =
	typeof(Forum.Prototype)
	& {
		state: state.State,
	}
	& channelBehaviour.ChannelBehaviour
	& textBehaviour.TextBehaviour
	& guildBehaviour.GuildBehaviour
	& threadBehaviour.ThreadBehaviour
	& forumBehaviour.ForumBehaviour

return Forum.Interface
