--[=[
	@class Classes.Channels.GuildVoice
	@__index Prototype
	@tag inherit:Classes.Channels.Channel
	@tag inherit:Classes.Channels.GuildBehaviour
	@tag inherit:Classes.Channels.VoiceBehaviour

	Implementation of the Discord GuildVoice class in Luau

	https://discord.com/developers/docs/resources/channel#channel-object
]=]

--[=[
	@prop state Classes.State
	@within Classes.Channels.GuildVoice
]=]

local apiTypes = require("../../../luau_packages/api_types")
local state = require("../../../luau_packages/state")

local channelBehaviour = require("../behaviour/channel")
local guildBehaviour = require("../behaviour/guild")
local voiceBehaviour = require("../behaviour/voice")

local GuildVoice = {}

GuildVoice.Interface = {}
GuildVoice.Prototype = {}
GuildVoice.Behaviours = {
	channelBehaviour,
	guildBehaviour,
	voiceBehaviour,
}

--[=[
	@within Classes.Channels.GuildVoice
	@private

	Responsible for syncing data to this guild voice channel object. This is typically called by the API when this object is
	created or updated.
]=]
function GuildVoice.Prototype.sync(self: GuildVoice, channelData: apiTypes.ChannelObject)
	for _, behaviour in GuildVoice.Behaviours do
		behaviour.inheritMethods(self)
		behaviour.inheritProperties(self, channelData)
	end
end

--[=[
	@within Classes.Channels.GuildVoice
	@private

	Responsible for constructing this class.
]=]
function GuildVoice.Interface.new(state: state.State, channelData: apiTypes.ChannelObject): GuildVoice
	local self = setmetatable(
		{
			state = state,
		} :: GuildVoice,
		{ __index = GuildVoice.Prototype }
	)

	self:sync(channelData)

	return self
end

export type GuildVoice = typeof(GuildVoice.Prototype) & {
	state: state.State,
} & channelBehaviour.ChannelBehaviour & voiceBehaviour.VoiceBehaviour & guildBehaviour.GuildBehaviour

return GuildVoice.Interface
