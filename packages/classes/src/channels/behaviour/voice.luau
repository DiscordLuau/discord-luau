local apiTypes = require("@api-types/apiTypes")

local VoiceBehaviour = {}

VoiceBehaviour.Interface = {}
VoiceBehaviour.Prototype = {}

function VoiceBehaviour.Interface.inheritProperties(class: any, channelData: apiTypes.ChannelObject)
	class.videoQualityMode = (channelData.video_quality_mode == 1 and "Auto" or "Full") :: VideoQualityMode

	class.bitrate = channelData.bitrate
	class.userLimit = channelData.user_limit
	class.rtcRegion = channelData.rtc_region
end

function VoiceBehaviour.Interface.inheritMethods(class: any)
	for key, value in VoiceBehaviour.Prototype do
		class[key] = value
	end
end

export type VideoQualityMode = "Auto" | "Full"

export type VoiceBehaviourMethods = typeof(VoiceBehaviour.Prototype)
export type VoiceBehaviourProperties = {
	bitrate: number,
	userLimit: number,
	rtcRegion: string?,
	videoQualityMode: VideoQualityMode,
}

export type VoiceBehaviour = VoiceBehaviourMethods & VoiceBehaviourProperties

return VoiceBehaviour.Interface
