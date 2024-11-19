--[[
	Implementation of the Discord GroupDM class in Luau

	https://discord.com/developers/docs/resources/channel#channel-object
]]

local apiTypes = require("@api-types/apiTypes")

local channelBehaviour = require("@classes/channels/behaviour/channel")
local groupDMBehaviours = require("@classes/channels/behaviour/groupDM")
local textBehaviour = require("@classes/channels/behaviour/text")

local state = require("@classes/state")

local GroupDM = {}

GroupDM.Interface = {}
GroupDM.Prototype = {}
GroupDM.Behaviours = {
	channelBehaviour,
	groupDMBehaviours,
	textBehaviour,
}

function GroupDM.Prototype.sync(self: GroupDM, channelData: apiTypes.ChannelObject)
	for _, behaviour in GroupDM.Behaviours do
		behaviour.inheritMethods(self)
		behaviour.inheritProperties(self, channelData)
	end
end

function GroupDM.Interface.new(state: state.State, channelData: apiTypes.ChannelObject): GroupDM
	local self = setmetatable(
		{
			state = state,
		} :: GroupDM,
		{ __index = GroupDM.Prototype }
	)

	self:sync(channelData)

	return self
end

export type GroupDM = typeof(GroupDM.Prototype) & {
	state: state.State,
} & channelBehaviour.ChannelBehaviour & groupDMBehaviours.DMBehaviour & textBehaviour.TextBehaviour

return GroupDM.Interface
