--[[
	Implementation of the Discord ChannelMention class in Luau

	https://discord.com/developers/docs/resources/message#channel-mention-object
]]

local apiTypes = require("@api-types/apiTypes")
local channelTypes = require("@api-types/channel")

local ChannelMention = {}

ChannelMention.Interface = {}
ChannelMention.Prototype = {}

function ChannelMention.Prototype.sync(self: ChannelMention, mentionData: apiTypes.ChannelMentionObject)
	self.type = (
		mentionData.type == 0 and "GuildText"
		or mentionData.type == 1 and "DM"
		or mentionData.type == 2 and "GuildVoice"
		or mentionData.type == 3 and "GroupDM"
		or mentionData.type == 4 and "GuildCategory"
		or mentionData.type == 5 and "GuildAnnouncement"
		or mentionData.type == 10 and "AnnouncementThread"
		or mentionData.type == 11 and "PublicThread"
		or mentionData.type == 12 and "PrivateThread"
		or mentionData.type == 13 and "GuildStageVoice"
		or mentionData.type == 14 and "GuildDirectory"
		or mentionData.type == 15 and "GuildForum"
		or mentionData.type == 16 and "GuildMedia"
	) :: channelTypes.ChannelType

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
	type: channelTypes.ChannelType,
	name: string,
}

return ChannelMention.Interface
