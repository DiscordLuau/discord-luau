--[=[
	@class Classes.Channels.VoiceBehaviour
	@__index Prototype

	Implementation of the Discord Voice Behaviour class in Luau. Responsible for implementing the various properties,
	and methods for a voice-able channels.
]=]

--[=[
	@prop videoQualityMode apiTypes.VideoQualityMode
	@within Classes.Channels.VoiceBehaviour
]=]

--[=[
	@prop bitrate number
	@within Classes.Channels.VoiceBehaviour
]=]

--[=[
	@prop userLimit number
	@within Classes.Channels.VoiceBehaviour
]=]

--[=[
	@prop rtcRegion string?
	@within Classes.Channels.VoiceBehaviour
]=]

--[=[
	@prop connection voice.Connection?
	@within Classes.Channels.VoiceBehaviour
]=]

--[=[
	@prop onReady emitter.Emitter<()>
	@within Classes.Channels.VoiceBehaviour
	Fires when the voice connection is established and ready to send and receive audio.
]=]

--[=[
	@prop onSpeaking emitter.Emitter<{ userId: string, ssrc: number, speaking: number }>
	@within Classes.Channels.VoiceBehaviour
	Fires when a user's speaking state changes. `speaking` is a bitmask (1 = Microphone, 2 = Soundshare, 4 = Priority).
]=]

--[=[
	@prop onClientConnect emitter.Emitter<{ userId: string }>
	@within Classes.Channels.VoiceBehaviour
	Fires when a user joins the voice channel.
]=]

--[=[
	@prop onClientDisconnect emitter.Emitter<{ userId: string }>
	@within Classes.Channels.VoiceBehaviour
	Fires when a user leaves the voice channel.
]=]

--[=[
	@prop onAudioFrame emitter.Emitter<{ userId: string?, ssrc: number, frame: buffer }>
	@within Classes.Channels.VoiceBehaviour
	Fires with a decoded PCM audio frame for each incoming Opus packet after jitter buffering.
]=]

--[=[
	@prop onRawAudioFrame emitter.Emitter<{ userId: string?, ssrc: number, frame: buffer }>
	@within Classes.Channels.VoiceBehaviour
	Fires with the raw Opus-encoded frame before PCM decoding. Use `onAudioFrame` for decoded audio.
]=]

--[=[
	@prop onDaveEpochTransition emitter.Emitter<number>
	@within Classes.Channels.VoiceBehaviour
	Fires when the DAVE E2EE MLS epoch advances. The argument is the new roster member count.
]=]

local apiTypes = require("../../../luau_packages/api_types")
local emitter = require("../../../luau_packages/emitter")
local voice = require("../../../luau_packages/voice")
local future = require("../../../luau_packages/future")
local rest = require("../../../luau_packages/rest")
local state = require("../../../luau_packages/state")
local bit = require("../../../luau_packages/bit")

local VoiceBehaviour = {}

VoiceBehaviour.Interface = {}
VoiceBehaviour.Prototype = {}

type VoiceChannel<T> = T & VoiceBehaviour & {
	state: state.State,
	guildId: string?,
	id: string,
}

--[=[
	@within Classes.Channels.VoiceBehaviour

	Connects the bot to this voice channel, initialising the voice WebSocket and UDP transport.
	Returns the underlying `Connection` object; signals can be listened to before or after calling this.
]=]
function VoiceBehaviour.Prototype.joinAsync<T>(self: VoiceChannel<T>): future.FutureLike<nil>
	return future.Future.new(function()
		local shards = self.state.webSocketManager.shards
		local shardCount = #shards

		local shardId: number

		if self.guildId and self.guildId ~= "" then
			shardId = bit.rshift(tonumber(self.guildId) :: number, 22) % shardCount
		else
			shardId = 0
		end

		local shard = shards[shardId + 1]

		assert(shard, `No shard found for shard ID {shardId}`)

		local connection = voice.connection.new({
			shard = shard :: any,
			guildId = self.guildId or "",
			channelId = self.id,
			userId = self.state.applicationId,
			logLevel = self.state.logLevel,
		})

		self.connection = connection
		self.state.voiceConnections[self.id] = connection

		connection.onReady:listen(function()
			self.onReady:invoke()
		end)

		connection.onSpeaking:listen(function(data)
			self.onSpeaking:invoke(data)
		end)

		connection.onClientConnect:listen(function(data)
			self.onClientConnect:invoke(data)
		end)

		connection.onClientDisconnect:listen(function(data)
			self.onClientDisconnect:invoke(data)
		end)

		connection.onAudioFrame:listen(function(data)
			self.onAudioFrame:invoke(data)
		end)

		connection.onRawAudioFrame:listen(function(data)
			self.onRawAudioFrame:invoke(data)
		end)

		connection.onDaveEpochTransition:listen(function(rosterSize)
			self.onDaveEpochTransition:invoke(rosterSize)
		end)

		connection:requestVoiceAsync():poll()
	end)
end

--[=[
	@within Classes.Channels.VoiceBehaviour

	Disconnects from the current voice channel. No-op if not connected.
]=]
function VoiceBehaviour.Prototype.leaveAsync<T>(self: VoiceChannel<T>): future.FutureLike<nil>
	return future.Future.new(function()
		if not self.connection then
			return
		end

		self.connection:disconnectAsync():poll()
		self.connection = nil
		self.state.voiceConnections[self.id] = nil
	end) :: future.FutureLike<nil>
end

--[=[
	@within Classes.Channels.VoiceBehaviour

	Encrypts and sends a raw Opus audio frame over UDP. The connection must be ready before calling this.
]=]
function VoiceBehaviour.Prototype.sendOpusAsync<T>(
	self: VoiceChannel<T>,
	audioFrame: buffer
): future.FutureLike<string, nil>
	assert(self.connection, "not connected to a voice channel")

	return self.connection:sendOpusAsync(audioFrame)
end

--[=[
	@within Classes.Channels.VoiceBehaviour

	Sets the bot's speaking state. Pass a bitmask of speaking flags: Microphone = 1, Soundshare = 2, Priority = 4.
]=]
function VoiceBehaviour.Prototype.setSpeakingAsync<T>(
	self: VoiceChannel<T>,
	speakingFlags: number
): future.FutureLike<string, nil>
	assert(self.connection, "not connected to a voice channel")

	return self.connection:setSpeakingAsync(speakingFlags)
end

--[=[
	@within Classes.Channels.VoiceBehaviour

	Sends a soundboard sound to this voice channel.
]=]
function VoiceBehaviour.Prototype.sendSoundboardSoundAsync<T>(
	self: VoiceChannel<T>,
	soundId: apiTypes.Snowflake,
	sourceGuildId: apiTypes.Snowflake?
): future.FutureLike<string, nil>
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.channel
			.sendSoundboardSoundAsync(request, self.id, {
				sound_id = soundId,
				source_guild_id = sourceGuildId,
			})
			:await()

		assert(response:isOk(), `{response:unwrapErr()}`)

		return nil
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Classes.Channels.VoiceBehaviour
]=]
function VoiceBehaviour.Interface.inheritProperties(class: any, channelData: apiTypes.ChannelObject)
	class.videoQualityMode = apiTypes.channel.VideoQualityMode[channelData.video_quality_mode]
	class.bitrate = channelData.bitrate
	class.userLimit = channelData.user_limit
	class.rtcRegion = channelData.rtc_region

	if not class.onReady then
		class.onReady = emitter.new()
		class.onSpeaking = emitter.new()
		class.onClientConnect = emitter.new()
		class.onClientDisconnect = emitter.new()
		class.onAudioFrame = emitter.new()
		class.onRawAudioFrame = emitter.new()
		class.onDaveEpochTransition = emitter.new()
	end
end

--[=[
	@within Classes.Channels.VoiceBehaviour
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

	connection: voice.Connection?,

	onReady: emitter.Emitter<()>,
	onSpeaking: emitter.Emitter<{ userId: string, ssrc: number, speaking: number }>,
	onClientConnect: emitter.Emitter<{ userId: string }>,
	onClientDisconnect: emitter.Emitter<{ userId: string }>,
	onAudioFrame: emitter.Emitter<{ userId: string?, ssrc: number, frame: buffer }>,
	onRawAudioFrame: emitter.Emitter<{ userId: string?, ssrc: number, frame: buffer }>,
	onDaveEpochTransition: emitter.Emitter<number>,
}

export type VoiceBehaviour = VoiceBehaviourMethods & VoiceBehaviourProperties

return VoiceBehaviour.Interface
