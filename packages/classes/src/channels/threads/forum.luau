--[[
	Implementation of the Discord Forum class in Luau

	https://discord.com/developers/docs/resources/channel#channel-object
]]

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
