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
	The guild's voice connection, once this channel object has joined or forwarded it; `joinAsync` resolves with the
	same object. Set `connection.decodeAudio = false` when only raw frames are needed: Opus decoding stops, and
	`onAudioFrame` no longer fires while `onRawAudioFrame` still does. `audio.player.new(connection)`, from
	`discord_luau/audio`, plays audio through it.
]=]

--[=[
	@prop onReady emitter.Emitter<()>
	@within Classes.Channels.VoiceBehaviour
	Fires when the voice connection is ready. With DAVE, audio flows only once `connection.dave.mediaReady` is true:
	the `discord_luau/audio` player waits for it, and `connection:awaitMediaReadyAsync()` resolves at once when it
	already is.
]=]

--[=[
	@prop onResumed emitter.Emitter<()>
	@within Classes.Channels.VoiceBehaviour
	Fires when the voice session is resumed after a drop; `onReady` fires for a new session.
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
	Fires with decoded stereo s16le 48 kHz PCM for one jitter slot (20 ms for 20 ms senders), loss concealment
	included. It stops about 100 ms after the speaker stops, and does not fire while `connection.decodeAudio` is false.
]=]

--[=[
	@prop onRawAudioFrame emitter.Emitter<{ userId: string?, ssrc: number, frame: buffer }>
	@within Classes.Channels.VoiceBehaviour
	Fires with the Opus payload, the RTP header removed and every encryption layer already undone, once for each packet
	the jitter buffer plays, in sequence order and at its pace; lost and late packets are skipped. Use `onAudioFrame`
	for decoded audio.
]=]

--[=[
	@prop onDaveEpochTransition emitter.Emitter<number>
	@within Classes.Channels.VoiceBehaviour
	Fires when a DAVE end-to-end encryption transition executes. The argument is the number of MLS group members, the
	bot included.
]=]

--[=[
	@prop onMediaReady emitter.Emitter<()>
	@within Classes.Channels.VoiceBehaviour
	Fires when audio can flow on the guild's voice connection: at once without DAVE, and with DAVE once the bot holds
	the group's key, which comes after `onReady`. It fires again once audio can flow after a DAVE group reset or a
	reconnect. Send audio after it; `connection:awaitMediaReadyAsync()` waits for it and `connection.dave.mediaReady`
	reads it. Without DAVE it fires at Session Description, just before `onReady`, so a listener added inside
	`onReady` misses it.
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

--[=[
	@within Classes.Channels.VoiceBehaviour
	@private

	The gateway shard that carries `guildId`.
]=]
function VoiceBehaviour.Prototype.shardForGuild<T>(self: VoiceChannel<T>, guildId: string): any
	local shards = self.state.webSocketManager.shards
	local shardId = (tonumber(bit.rshift(guildId, 22)) :: number) % #shards
	local shard = shards[shardId + 1]

	assert(shard, `No shard found for shard ID {shardId}`)

	return shard
end

--[=[
	@within Classes.Channels.VoiceBehaviour
	@private

	Forwards the connection's events to this channel object's emitters until the connection closes, then clears this
	object's `connection` and the guild's entry in `state.voiceConnections` if they still hold it.
]=]
function VoiceBehaviour.Prototype.forwardEvents<T>(self: VoiceChannel<T>, connection: voice.Connection)
	local guildId = self.guildId :: string
	local disconnects: { () -> () } = {}

	if self.connection == connection then
		connection.logger:debug(`channel {self.id} already forwards this voice connection's events`)

		return
	end

	self.connection = connection

	table.insert(
		disconnects,
		connection.onReady:listen(function()
			self.onReady:invoke()
		end)
	)
	table.insert(
		disconnects,
		connection.onSpeaking:listen(function(data)
			self.onSpeaking:invoke(data)
		end)
	)
	table.insert(
		disconnects,
		connection.onClientConnect:listen(function(data)
			self.onClientConnect:invoke(data)
		end)
	)
	table.insert(
		disconnects,
		connection.onClientDisconnect:listen(function(data)
			self.onClientDisconnect:invoke(data)
		end)
	)
	table.insert(
		disconnects,
		connection.onAudioFrame:listen(function(data)
			self.onAudioFrame:invoke(data)
		end)
	)
	table.insert(
		disconnects,
		connection.onRawAudioFrame:listen(function(data)
			self.onRawAudioFrame:invoke(data)
		end)
	)
	table.insert(
		disconnects,
		connection.onDaveEpochTransition:listen(function(rosterSize)
			self.onDaveEpochTransition:invoke(rosterSize)
		end)
	)
	table.insert(
		disconnects,
		connection.onMediaReady:listen(function()
			self.onMediaReady:invoke()
		end)
	)
	table.insert(
		disconnects,
		connection.onResumed:listen(function()
			self.onResumed:invoke()
		end)
	)
	table.insert(
		disconnects,
		connection.onClosed:listen(function()
			for _, disconnect in disconnects do
				disconnect()
			end

			if self.connection == connection then
				self.connection = nil
			end

			if self.state.voiceConnections[guildId] == connection then
				self.state.voiceConnections[guildId] = nil
			end
		end)
	)
end

--[=[
	@within Classes.Channels.VoiceBehaviour

	Joins this voice channel and resolves with the guild's `Connection` once it is ready. A guild has one connection:
	joining the channel it is already in resolves with it, and joining another channel of the guild leaves the old one
	first. Fails before READY (the bot's user id is not known yet), without the `GuildVoiceStates` intent, or when the
	connection closes before it is ready.
]=]
function VoiceBehaviour.Prototype.joinAsync<T>(self: VoiceChannel<T>): future.FutureLike<string, voice.Connection>
	return future.Future.new(function()
		local guildId = self.guildId
		local userId = self.state.userId
		local voiceStatesIntent = bit32.lshift(1, apiTypes.gateway.intents.GuildVoiceStates)

		assert(guildId and guildId ~= "", `voice join needs a guild voice channel`)
		assert(userId ~= "", `voice join needs the bot's user id; wait for onAllShardsReady`)
		assert(bit32.btest(self.state.intents, voiceStatesIntent), `voice needs the GuildVoiceStates intent`)

		while true do
			local existing: voice.Connection? = self.state.voiceConnections[guildId]

			if existing and existing.status ~= "closed" and existing.channelId == self.id then
				self:forwardEvents(existing)

				local joined = existing:joinAsync():await()

				assert(joined:isOk(), `{joined:unwrapErr()}`)

				return existing
			elseif existing and existing.status ~= "closed" then
				self.state.logger:info(`leaving voice channel {existing.channelId} before joining {self.id}`)

				local left = existing:leaveAsync():await()

				if left:isErr() then
					self.state.logger:warn(
						`leaving voice channel {existing.channelId} failed, destroying the connection: {left:unwrapErr()}`
					)
					existing:destroy()
				end
			else
				local connection = voice.connection.new({
					shard = self:shardForGuild(guildId),
					guildId = guildId,
					channelId = self.id,
					userId = userId,
					logLevel = self.state.logLevel,
				})

				self.state.voiceConnections[guildId] = connection
				self:forwardEvents(connection)

				local joined = connection:joinAsync():await()

				assert(joined:isOk(), `{joined:unwrapErr()}`)

				return connection
			end
		end
	end) :: future.FutureLike<string, voice.Connection>
end

--[=[
	@within Classes.Channels.VoiceBehaviour

	Leaves voice in this channel's guild, from any channel object of the guild. A no-op when the bot is not in voice
	there.
]=]
function VoiceBehaviour.Prototype.leaveAsync<T>(self: VoiceChannel<T>): future.FutureLike<string, nil>
	return future.Future.new(function()
		local guildId = self.guildId
		local connection: voice.Connection? = if guildId then self.state.voiceConnections[guildId] else nil

		if not connection then
			self.state.logger:debug(`leaveAsync on channel {self.id}: the bot is not in voice in this guild`)

			return
		end

		local left = connection:leaveAsync():await()

		assert(left:isOk(), `{left:unwrapErr()}`)
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Classes.Channels.VoiceBehaviour

	Encrypts and sends a raw Opus audio frame over the guild's voice connection, which must be ready. Fails with `not
	connected to a voice channel` when the guild has no connection, and with the connection's error when the send
	fails.
]=]
function VoiceBehaviour.Prototype.sendOpusAsync<T>(
	self: VoiceChannel<T>,
	audioFrame: buffer
): future.FutureLike<string, nil>
	return future.Future.new(function()
		local guildId = self.guildId
		local connection: voice.Connection? = self.connection
			or (if guildId then self.state.voiceConnections[guildId] else nil)

		assert(connection, "not connected to a voice channel")

		local sent = connection:sendOpusAsync(audioFrame):await()

		assert(sent:isOk(), `{sent:unwrapErr()}`)
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Classes.Channels.VoiceBehaviour

	Sets the bot's speaking state on the guild's voice connection. Pass a bitmask of speaking flags: Microphone = 1,
	Soundshare = 2, Priority = 4. Fails with `not connected to a voice channel` when the guild has no connection, and
	with the connection's error when the send fails.
]=]
function VoiceBehaviour.Prototype.setSpeakingAsync<T>(
	self: VoiceChannel<T>,
	speakingFlags: number
): future.FutureLike<string, nil>
	return future.Future.new(function()
		local guildId = self.guildId
		local connection: voice.Connection? = self.connection
			or (if guildId then self.state.voiceConnections[guildId] else nil)

		assert(connection, "not connected to a voice channel")

		local spoke = connection:setSpeakingAsync(speakingFlags):await()

		assert(spoke:isOk(), `{spoke:unwrapErr()}`)
	end) :: future.FutureLike<string, nil>
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
		class.onResumed = emitter.new()
		class.onSpeaking = emitter.new()
		class.onClientConnect = emitter.new()
		class.onClientDisconnect = emitter.new()
		class.onAudioFrame = emitter.new()
		class.onRawAudioFrame = emitter.new()
		class.onDaveEpochTransition = emitter.new()
		class.onMediaReady = emitter.new()
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

type VoiceChannel<T> = T & VoiceBehaviour & {
	state: state.State,
	guildId: string?,
	id: string,
}

export type VoiceBehaviourMethods = typeof(VoiceBehaviour.Prototype)
export type VoiceBehaviourProperties = {
	bitrate: number,
	userLimit: number,
	rtcRegion: string?,
	videoQualityMode: apiTypes.VideoQualityMode,

	connection: voice.Connection?,

	onReady: emitter.Emitter<()>,
	onResumed: emitter.Emitter<()>,
	onSpeaking: emitter.Emitter<{ userId: string, ssrc: number, speaking: number }>,
	onClientConnect: emitter.Emitter<{ userId: string }>,
	onClientDisconnect: emitter.Emitter<{ userId: string }>,
	onAudioFrame: emitter.Emitter<{ userId: string?, ssrc: number, frame: buffer }>,
	onRawAudioFrame: emitter.Emitter<{ userId: string?, ssrc: number, frame: buffer }>,
	onDaveEpochTransition: emitter.Emitter<number>,
	onMediaReady: emitter.Emitter<()>,
}

export type VoiceBehaviour = VoiceBehaviourMethods & VoiceBehaviourProperties

return VoiceBehaviour.Interface
