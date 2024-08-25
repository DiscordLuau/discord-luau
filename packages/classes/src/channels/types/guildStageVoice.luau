--[[
	Implementation of the Discord GuildStageVoice class in Luau

	https://discord.com/developers/docs/resources/channel#channel-object
]]

local apiTypes = require("@api-types/apiTypes")

local channelBehaviour = require("@classes/channels/behaviour/channel")
local guildBehaviour = require("@classes/channels/behaviour/guild")
local voiceBehaviour = require("@classes/channels/behaviour/voice")

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

function GuildStageVoice.Interface.new(ChannelData: apiTypes.ChannelObject): GuildStageVoice
	local self = setmetatable({} :: GuildStageVoice, { __index = GuildStageVoice.Prototype })

	self:sync(ChannelData)

	return self
end

export type GuildStageVoice =
	typeof(GuildStageVoice.Prototype)
	& {}
	& channelBehaviour.ChannelBehaviour
	& voiceBehaviour.VoiceBehaviour
	& guildBehaviour.GuildBehaviour

return GuildStageVoice.Interface
