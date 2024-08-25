--[[
	Implementation of the Discord DM class in Luau

	https://discord.com/developers/docs/resources/channel#channel-object
]]

local apiTypes = require("@api-types/apiTypes")

local channelBehaviour = require("@classes/channels/behaviour/channel")
local textBehaviour = require("@classes/channels/behaviour/text")

local DM = {}

DM.Interface = {}
DM.Prototype = {}
DM.Behaviours = {
	channelBehaviour,
	textBehaviour,
}

function DM.Prototype.sync(self: DM, channelData: apiTypes.ChannelObject)
	for _, behaviour in DM.Behaviours do
		behaviour.inheritMethods(self)
		behaviour.inheritProperties(self, channelData)
	end
end

function DM.Interface.new(channelData: apiTypes.ChannelObject): DM
	local self = setmetatable({} :: DM, { __index = DM.Prototype })

	self:sync(channelData)

	return self
end

export type DM = typeof(DM.Prototype) & {} & channelBehaviour.ChannelBehaviour & textBehaviour.TextBehaviour

return DM.Interface
