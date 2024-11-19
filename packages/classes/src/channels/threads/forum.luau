--[[
	Implementation of the Discord Forum class in Luau

	https://discord.com/developers/docs/resources/channel#channel-object
]]

local apiTypes = require("@api-types/apiTypes")

local channelBehaviour = require("@classes/channels/behaviour/channel")
local guildBehaviour = require("@classes/channels/behaviour/guild")
local textBehaviour = require("@classes/channels/behaviour/text")
local threadBehaviour = require("@classes/channels/behaviour/thread")
local forumBehaviour = require("@classes/channels/behaviour/forum")

local state = require("@classes/state")

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

function Forum.Prototype.sync(self: Forum, channelData: apiTypes.ChannelObject)
	for _, behaviour in Forum.Behaviours do
		behaviour.inheritMethods(self)
		behaviour.inheritProperties(self, channelData)
	end
end

function Forum.Interface.new(state: state.State, channelData: apiTypes.ChannelObject): Forum
	local self = setmetatable(
		{
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
