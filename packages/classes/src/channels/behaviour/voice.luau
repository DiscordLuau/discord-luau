--[[
	Voice Behaviour, responsible for implementing the various properties, and methods for a voice-able channels.
]]

local apiTypes = require("../../../lune_packages/api_types")
local future = require("../../../luau_packages/future")

local VoiceBehaviour = {}

VoiceBehaviour.Interface = {}
VoiceBehaviour.Prototype = {}

--[[
	Will connect the bot to this voice chat, will also set up the voice chat websocket and allow the developer
	to start querying voice related information.
]]
function VoiceBehaviour.Prototype.joinAsync()
	return future.Future.new(function()
		error(`Discord-Luau voice chat implementation is not finished!`)
	end)
end

--[[
	Will leave the current voice chat, if there is one.
]]
function VoiceBehaviour.Prototype.leaveAsync()
	return future.Future.new(function()
		error(`Discord-Luau voice chat implementation is not finished!`)
	end)
end

function VoiceBehaviour.Interface.inheritProperties(class: any, channelData: apiTypes.ChannelObject)
	class.videoQualityMode = apiTypes.channel.VideoQualityMode[channelData.video_quality_mode]

	class.bitrate = channelData.bitrate
	class.userLimit = channelData.user_limit
	class.rtcRegion = channelData.rtc_region
end

function VoiceBehaviour.Interface.inheritMethods(class: any)
	for key, value in VoiceBehaviour.Prototype do
		class[key] = value
	end
end

export type VoiceBehaviourMethods = typeof(VoiceBehaviour.Prototype)
export type VoiceBehaviourProperties = {
	bitrate: number,
	userLimit: number,
	rtcRegion: string?,
	videoQualityMode: apiTypes.VideoQualityMode,
}

export type VoiceBehaviour = VoiceBehaviourMethods & VoiceBehaviourProperties

return VoiceBehaviour.Interface
