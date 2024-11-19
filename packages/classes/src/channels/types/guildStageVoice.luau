--[[
	Implementation of the Discord GuildStageVoice class in Luau

	https://discord.com/developers/docs/resources/channel#channel-object
]]

local apiTypes = require("@api-types/apiTypes")

local channelBehaviour = require("@classes/channels/behaviour/channel")
local guildBehaviour = require("@classes/channels/behaviour/guild")
local voiceBehaviour = require("@classes/channels/behaviour/voice")

local state = require("@classes/state")

local GuildStageVoice = {}

GuildStageVoice.Interface = {}
GuildStageVoice.Prototype = {}
GuildStageVoice.Behaviours = {
	channelBehaviour,
	guildBehaviour,
	voiceBehaviour,
}

function GuildStageVoice.Prototype.sync(self: GuildStageVoice, channelData: apiTypes.ChannelObject)
	for _, behaviour in GuildStageVoice.Behaviours do
		behaviour.inheritMethods(self)
		behaviour.inheritProperties(self, channelData)
	end
end

function GuildStageVoice.Interface.new(state: state.State, channelData: apiTypes.ChannelObject): GuildStageVoice
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
