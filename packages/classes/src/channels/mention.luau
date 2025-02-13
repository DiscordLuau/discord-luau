--[[
	Implementation of the Discord ChannelMention class in Luau

	https://discord.com/developers/docs/resources/message#channel-mention-object
]]

local apiTypes = require("../../lune_packages/api_types")

local ChannelMention = {}

ChannelMention.Interface = {}
ChannelMention.Prototype = {}

function ChannelMention.Prototype.sync(self: ChannelMention, mentionData: apiTypes.ChannelMentionObject)
	self.type = apiTypes.channel.ChannelTypes[mentionData.type]

	self.id = mentionData.id
	self.name = mentionData.name
	self.guildId = mentionData.guild_id
end

function ChannelMention.Interface.new(mentionData: apiTypes.ChannelMentionObject): ChannelMention
	local self = setmetatable({} :: ChannelMention, { __index = ChannelMention.Prototype })

	self:sync(mentionData)

	return self
end

export type ChannelMention = typeof(ChannelMention.Prototype) & {
	id: apiTypes.Snowflake,
	guildId: apiTypes.Snowflake,
	type: apiTypes.ChannelType,
	name: string,
}

return ChannelMention.Interface
