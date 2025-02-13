--[[
	Voice Behaviour, responsible for implementing the various properties, and methods for a voice-able channels.
]]

local apiTypes = require("../../../lune_packages/api_types")

local VoiceBehaviour = {}

VoiceBehaviour.Interface = {}
VoiceBehaviour.Prototype = {}

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
