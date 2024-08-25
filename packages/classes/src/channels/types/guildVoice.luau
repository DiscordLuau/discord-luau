--[[
	Implementation of the Discord GuildVoice class in Luau

	https://discord.com/developers/docs/resources/channel#channel-object
]]

local apiTypes = require("@api-types/apiTypes")

local channelBehaviour = require("@classes/channels/behaviour/channel")
local guildBehaviour = require("@classes/channels/behaviour/guild")
local voiceBehaviour = require("@classes/channels/behaviour/voice")

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

function GuildVoice.Interface.new(channelData: apiTypes.ChannelObject): GuildVoice
	local self = setmetatable({} :: GuildVoice, { __index = GuildVoice.Prototype })

	self:sync(channelData)

	return self
end

export type GuildVoice =
	typeof(GuildVoice.Prototype)
	& {}
	& channelBehaviour.ChannelBehaviour
	& voiceBehaviour.VoiceBehaviour
	& guildBehaviour.GuildBehaviour

return GuildVoice.Interface
