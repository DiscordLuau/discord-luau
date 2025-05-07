--[=[
	@class Classes.GuildStageVoice
	@__index Prototype

	Implementation of the Discord GuildStageVoice class in Luau

	https://discord.com/developers/docs/resources/channel#channel-object
]=]

local apiTypes = require("../../../lune_packages/api_types")
local state = require("../../../lune_packages/state")

local channelBehaviour = require("../behaviour/channel")
local guildBehaviour = require("../behaviour/guild")
local voiceBehaviour = require("../behaviour/voice")

local GuildStageVoice = {}

GuildStageVoice.Interface = {}
GuildStageVoice.Prototype = {}
GuildStageVoice.Behaviours = {
	channelBehaviour,
	guildBehaviour,
	voiceBehaviour,
}

--[=[
	@within Classes.GuildStageVoice
	@private

	Responsible for syncing data to this guild stage voice object. This is typically called by the API when this object is
	created or updated.
]=]
function GuildStageVoice.Prototype.sync(self: GuildStageVoice, channelData: apiTypes.ChannelObject)
	for _, behaviour in GuildStageVoice.Behaviours do
		behaviour.inheritMethods(self)
		behaviour.inheritProperties(self, channelData)
	end
end

--[=[
	@within Classes.GuildStageVoice
	@private

	Responsible for constructing this class.
]=]
function GuildStageVoice.Interface.new(state: state.State, channelData: apiTypes.ChannelObject): GuildStageVoice
	--[=[
		@prop state Classes.State
		@within Classes.GuildStageVoice
	]=]
	local self = setmetatable(
		{
			state = state,
		} :: GuildStageVoice,
		{ __index = GuildStageVoice.Prototype }
	)

	self:sync(channelData)

	return self
end

export type GuildStageVoice = typeof(GuildStageVoice.Prototype) & {
	state: state.State,
} & channelBehaviour.ChannelBehaviour & voiceBehaviour.VoiceBehaviour & guildBehaviour.GuildBehaviour

return GuildStageVoice.Interface
