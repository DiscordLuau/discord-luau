--[[
	Channel Behaviour, responsible for implementing the various properties, and methods for a generic
	channel object.
]]

local apiTypes: string = require("@api-types/apiTypes")
local channelTypes = require("@api-types/channel")

local channelBitflags = require("@classes/bitflags/channel")

local ChannelBehaviour = {}

ChannelBehaviour.Interface = {}
ChannelBehaviour.Prototype = {}

-- https://discord.com/developers/docs/resources/guild#modify-guild-channel-positions

function ChannelBehaviour.Interface.inheritProperties(class: any, channelData: apiTypes.ChannelObject)
	class.type = channelTypes.ChannelTypes[channelData.type]

	class.id = channelData.id
	class.name = channelData.name

	class.flags = channelData.flags and channelBitflags.new(channelData.flags)
end

function ChannelBehaviour.Interface.inheritMethods(class: any)
	for key, value in ChannelBehaviour.Prototype do
		class[key] = value
	end
end

export type ChannelBehaviourMethods = typeof(ChannelBehaviour.Prototype)
export type ChannelBehaviourProperties = {
	id: apiTypes.Snowflake,
	type: channelTypes.ChannelType,
	name: string?,
	flags: channelBitflags.ChannelBitflag?,
}

export type ChannelBehaviour = ChannelBehaviourMethods & ChannelBehaviourProperties

return ChannelBehaviour.Interface
