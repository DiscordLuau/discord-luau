--[=[
	@class Classes.Guild.VoiceState
	@__index Prototype

	Implementation of the Discord VoiceState class in Luau

	https://discord.com/developers/docs/resources/voice#voice-state-object
]=]

--[=[
	@prop guildId string?
	@within Classes.Guild.VoiceState
	The guild id this voice state is for
]=]

--[=[
	@prop channelId string?
	@within Classes.Guild.VoiceState
	The channel id this user is connected to
]=]

--[=[
	@prop userId string
	@within Classes.Guild.VoiceState
	The user id this voice state is for
]=]

--[=[
	@prop member Classes.GuildMember?
	@within Classes.Guild.VoiceState
	The guild member this voice state is for
]=]

--[=[
	@prop sessionId string
	@within Classes.Guild.VoiceState
	The session id for this voice state
]=]

--[=[
	@prop deaf boolean
	@within Classes.Guild.VoiceState
	Whether this user is deafened by the server
]=]

--[=[
	@prop mute boolean
	@within Classes.Guild.VoiceState
	Whether this user is muted by the server
]=]

--[=[
	@prop selfDeaf boolean
	@within Classes.Guild.VoiceState
	Whether this user is locally deafened
]=]

--[=[
	@prop selfMute boolean
	@within Classes.Guild.VoiceState
	Whether this user is locally muted
]=]

--[=[
	@prop selfStream boolean?
	@within Classes.Guild.VoiceState
	Whether this user is streaming using "Go Live"
]=]

--[=[
	@prop selfVideo boolean
	@within Classes.Guild.VoiceState
	Whether this user's camera is enabled
]=]

--[=[
	@prop suppress boolean
	@within Classes.Guild.VoiceState
	Whether this user's permission to speak is denied
]=]

--[=[
	@prop requestToSpeakTimestamp DateTime?
	@within Classes.Guild.VoiceState
	The time at which the user requested to speak
]=]

local apiTypes = require("../../luau_packages/api_types")
local state = require("../../luau_packages/state")
local stdPolyfills = require("../../luau_packages/std_polyfills")

local member = require("./member")

local VoiceState = {}

VoiceState.Interface = {}
VoiceState.Prototype = {}

--[=[
	@within Classes.Guild.VoiceState
	@private

	Responsible for syncing data to this voice state object. This is typically called by the API when this object is
	created or updated.
]=]
function VoiceState.Prototype.sync(self: VoiceState, voiceStateData: apiTypes.VoiceStateObject)
	self.guildId = voiceStateData.guild_id

	self.channelId = voiceStateData.channel_id

	self.userId = voiceStateData.user_id

	self.member = voiceStateData.member and voiceStateData.guild_id
		and member.new(self.state, voiceStateData.guild_id, voiceStateData.member)

	self.sessionId = voiceStateData.session_id

	self.deaf = voiceStateData.deaf

	self.mute = voiceStateData.mute

	self.selfDeaf = voiceStateData.self_deaf

	self.selfMute = voiceStateData.self_mute

	self.selfStream = voiceStateData.self_stream

	self.selfVideo = voiceStateData.self_video

	self.suppress = voiceStateData.suppress

	self.requestToSpeakTimestamp = voiceStateData.request_to_speak_timestamp
		and stdPolyfills.datetime.fromIsoDate(voiceStateData.request_to_speak_timestamp)
end

--[=[
	@within Classes.Guild.VoiceState
	@private

	Responsible for constructing this class.
]=]
function VoiceState.Interface.new(voiceStateState: state.State, voiceStateData: apiTypes.VoiceStateObject): VoiceState
	local self = setmetatable(
		{
			state = voiceStateState,
		} :: VoiceState,
		{ __index = VoiceState.Prototype }
	)

	self:sync(voiceStateData)

	return self
end

export type VoiceState = typeof(VoiceState.Prototype) & {
	state: state.State,

	guildId: apiTypes.Snowflake?,
	channelId: apiTypes.Snowflake?,
	userId: apiTypes.Snowflake,
	member: member.Member?,
	sessionId: string,
	deaf: boolean,
	mute: boolean,
	selfDeaf: boolean,
	selfMute: boolean,
	selfStream: boolean?,
	selfVideo: boolean,
	suppress: boolean,
	requestToSpeakTimestamp: stdPolyfills.DateTime?,
}

return VoiceState.Interface
