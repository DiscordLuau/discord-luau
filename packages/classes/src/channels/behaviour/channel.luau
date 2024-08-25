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

function ChannelBehaviour.Interface.inheritProperties(class: any, channelData: apiTypes.ChannelObject)
	class.type = channelData.type == 0 and "GuildText"
		or channelData.type == 1 and "DM"
		or channelData.type == 2 and "GuildVoice"
		or channelData.type == 3 and "GroupDM"
		or channelData.type == 4 and "GuildCategory"
		or channelData.type == 5 and "GuildAnnouncement"
		or channelData.type == 10 and "AnnouncementThread"
		or channelData.type == 11 and "PublicThread"
		or channelData.type == 12 and "PrivateThread"
		or channelData.type == 13 and "GuildStageVoice"
		or channelData.type == 14 and "GuildDirectory"
		or channelData.type == 15 and "GuildForum"
		or channelData.type == 16 and "GuildMedia"

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
