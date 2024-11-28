--[[
	Implementation of the Discord GuildVoice class in Luau

	https://discord.com/developers/docs/resources/channel#channel-object
]]

local apiTypes = require("../../../lune_packages/api_types")
local state = require("../../../lune_packages/state")

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

function GuildVoice.Prototype.sync(self: GuildVoice, channelData: apiTypes.ChannelObject)
	for _, behaviour in GuildVoice.Behaviours do
		behaviour.inheritMethods(self)
		behaviour.inheritProperties(self, channelData)
	end
end

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
