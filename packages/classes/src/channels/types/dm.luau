--[=[
	@class Classes.DM
	@__index Prototype

	Implementation of the Discord DM class in Luau

	https://discord.com/developers/docs/resources/channel#channel-object
]=]

local apiTypes = require("../../../lune_packages/api_types")
local state = require("../../../lune_packages/state")

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
	@within Classes.DM
	@private

	Responsible for syncing data to this DM object. This is typically called by the API when this object is
	created or updated.
]=]
function DM.Prototype.sync(self: DM, channelData: apiTypes.ChannelObject)
	for _, behaviour in DM.Behaviours do
		behaviour.inheritMethods(self)
		behaviour.inheritProperties(self, channelData)
	end
end

--[=[
	@within Classes.DM
	@private

	Responsible for constructing this class.
]=]
function DM.Interface.new(state: state.State, channelData: apiTypes.ChannelObject): DM
	local self = setmetatable(
		{
			--[=[
				@prop state State
				@within Classes.DM
			]=]
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
