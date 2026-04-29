--[=[
	@class Classes.Channels.DM
	@__index Prototype
	@tag inherit:Classes.Channels.Channel
	@tag inherit:Classes.Channels.TextBehaviour

	Implementation of the Discord DM class in Luau

	https://discord.com/developers/docs/resources/channel#channel-object
]=]

--[=[
	@prop state State
	@within Classes.Channels.DM
]=]

local apiTypes = require("../../../luau_packages/api_types")
local state = require("../../../luau_packages/state")

local channelBehaviour = require("../behaviour/channel")
local textBehaviour = require("../behaviour/text")

local DM = {}

DM.Interface = {}
DM.Prototype = {}
DM.Behaviours = {
	channelBehaviour,
	textBehaviour,
}

--[=[
	@within Classes.Channels.DM
	@private

	Responsible for syncing data to this DM object. This is typically called by the API when this object is
	created or updated.
]=]
function DM.Prototype.sync(self: DM, channelData: apiTypes.ChannelObject): nil
	for _, behaviour in DM.Behaviours do
		behaviour.inheritMethods(self)
		behaviour.inheritProperties(self, channelData)
	end
end

--[=[
	@within Classes.Channels.DM
	@private

	Responsible for constructing this class.
]=]
function DM.Interface.new(state: state.State, channelData: apiTypes.ChannelObject): DM
	local self = setmetatable(
		{
			state = state,
		} :: DM,
		{ __index = DM.Prototype }
	)

	self:sync(channelData)

	return self
end

export type DM = typeof(DM.Prototype) & {
	state: state.State,
} & channelBehaviour.ChannelBehaviour & textBehaviour.TextBehaviour

return DM.Interface
