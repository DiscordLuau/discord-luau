--[=[
	@class Classes.GroupDM
	@__index Prototype

	Implementation of the Discord GroupDM class in Luau

	https://discord.com/developers/docs/resources/channel#channel-object
]=]

local apiTypes = require("../../../lune_packages/api_types")
local state = require("../../../lune_packages/state")

local channelBehaviour = require("../behaviour/channel")
local groupDMBehaviours = require("../behaviour/groupDM")
local textBehaviour = require("../behaviour/text")

local GroupDM = {}

GroupDM.Interface = {}
GroupDM.Prototype = {}
GroupDM.Behaviours = {
	channelBehaviour,
	groupDMBehaviours,
	textBehaviour,
}

--[=[
	@within Classes.GroupDM
	@private

	Responsible for syncing data to this group DM object. This is typically called by the API when this object is
	created or updated.
]=]
function GroupDM.Prototype.sync(self: GroupDM, channelData: apiTypes.ChannelObject)
	for _, behaviour in GroupDM.Behaviours do
		behaviour.inheritMethods(self)
		behaviour.inheritProperties(self, channelData)
	end
end

--[=[
	@within Classes.GroupDM
	@private

	Responsible for constructing this class.
]=]
function GroupDM.Interface.new(state: state.State, channelData: apiTypes.ChannelObject): GroupDM
	local self = setmetatable(
		{
			--[=[
				@prop state Classes.State
				@within Classes.GroupDM
			]=]
			state = state,
		} :: GroupDM,
		{ __index = GroupDM.Prototype }
	)

	self:sync(channelData)

	return self
end

export type GroupDM = typeof(GroupDM.Prototype) & {
	state: state.State,
} & channelBehaviour.ChannelBehaviour & groupDMBehaviours.GroupDMBehaviour & textBehaviour.TextBehaviour

return GroupDM.Interface
