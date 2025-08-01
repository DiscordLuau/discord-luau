--[=[
	@class Classes.VoiceBehaviour
	@__index Prototype

	Implementation of the Discord Voice Behaviour class in Luau. Responsible for implementing the various properties, 
	and methods for a voice-able channels.
]=]

local apiTypes = require("../../../lune_packages/api_types")
local future = require("../../../luau_packages/future")

local VoiceBehaviour = {}

VoiceBehaviour.Interface = {}
VoiceBehaviour.Prototype = {}

--[=[
	@within Classes.VoiceBehaviour
	@private

	Will connect the bot to this voice chat, will also set up the voice chat websocket and allow the developer
	to start querying voice related information.
]=]
function VoiceBehaviour.Prototype.joinAsync()
	return future.Future.new(function()
		error(`Discord-Luau voice chat implementation is not finished!`)
	end)
end

--[=[
	@within Classes.VoiceBehaviour
	@private

	Will leave the current voice chat, if there is one.
]=]
function VoiceBehaviour.Prototype.leaveAsync()
	return future.Future.new(function()
		error(`Discord-Luau voice chat implementation is not finished!`)
	end)
end

--[=[
	@within Classes.VoiceBehaviour
	@private
]=]
function VoiceBehaviour.Interface.inheritProperties(class: any, channelData: apiTypes.ChannelObject)
	--[=[
		@prop videoQualityMode apiTypes.VideoQualityMode
		@within Classes.VoiceBehaviour
		The video quality mode for the voice channel, determining the quality of video streams.
	]=]
	class.videoQualityMode = apiTypes.channel.VideoQualityMode[channelData.video_quality_mode]

	--[=[
		@prop bitrate number
		@within Classes.VoiceBehaviour
		The bitrate of the voice channel, determining the quality of audio transmission.
	]=]
	class.bitrate = channelData.bitrate

	--[=[
		@prop userLimit number
		@within Classes.VoiceBehaviour
		The maximum number of users that can join the voice channel.
	]=]
	class.userLimit = channelData.user_limit

	--[=[
		@prop rtcRegion string?
		@within Classes.VoiceBehaviour
		The RTC region for the voice channel, determining which server handles the voice connection.
	]=]
	class.rtcRegion = channelData.rtc_region
end

--[=[
	@within Classes.VoiceBehaviour
	@private
]=]
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
