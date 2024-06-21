-- https://discord.com/developers/docs/resources/channel#channel-object-channel-types

local ChannelType = {
	GuildTextChannel = 0,
	UserDMChannel = 1,
	GuildVoiceChannel = 2,
	UserGroupChannel = 3,
	GuildCategory = 4,
	GuildAnnouncement = 5,
	GuildAnnouncementThread = 10,
	GuildPublicThread = 11,
	GuildPrivateThread = 12,
	GuildStageVoiceChannel = 13,
	GuildDirectory = 14,
	GuildForumChannel = 15,
	GuildMediaChannel = 16,
}

export type ChannelType = number

return ChannelType
