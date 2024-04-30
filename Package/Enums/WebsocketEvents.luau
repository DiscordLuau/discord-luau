return {
	Ready = "READY",

	MessageCreate = "MESSAGE_CREATE",
	MessageUpdate = "MESSAGE_UPDATE",
	MessageDeleted = "MESSAGE_DELETE",
	MessageBulkDeleted = "MESSAGE_DELETE_BULK", --

	ChannelCreate = "CHANNEL_CREATE",
	ChannelUpdate = "CHANNEL_UPDATE",
	ChannelDeleted = "CHANNEL_DELETE",

	UserUpdated = "USER_UPDATE",

	ChannelPinsUpdate = "CHANNEL_PINS_UPDATE",

	GuildCreate = "GUILD_CREATE",
	GuildUpdate = "GUILD_UPDATE",
	GuildDeleted = "GUILD_DELETE",

	GuildMemberBanned = "GUILD_BAN_ADDED",
	GuildMemberUnbanned = "GUILD_BAN_REMOVE",

	GuildMemberJoined = "GUILD_MEMBER_JOINED",
	GuildMemberLeft = "GUILD_MEMBER_LEFT",
	GuildMemberUpdated = "GUILD_MEMBER_UPDATE",

	InteractionCreate = "INTERACTION_CREATE",

	VoiceServerUpdate = "VOICE_SERVER_UPDATE",
	VoiceStateUpdate = "VOICE_STATE_UPDATE"
}