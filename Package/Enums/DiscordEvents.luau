-- Events that the library will fire from the DiscordClient instance.

local DiscordEvents = {
	Ready = "Ready",

	Message = "Message",
	MessageChanged = "MessageChanged",
	MessageDeleted = "MessageDeleted",
	MessageBulkDeleted = "MessageDeleteBulk",

	ChannelCreate = "ChannelCreate",
	ChannelUpdate = "ChannelUpdate",
	ChannelDelete = "ChannelDelete",

	UserUpdated = "UserUpdate",

	ChannelPinsUpdate = "ChannelPinsUpdate",

	GuildCreate = "GuildCreate",
	GuildUpdate = "GuildUpdate",
	GuildDelete = "GuildDelete",

	GuildMemberBanned = "GuildBanAdded",
	GuildMemberUnbanned = "GuildBanRemoved",

	GuildMemberJoined = "GuildMemberJoined",
	GuildMemberLeft = "GuildMemberRemove",
	GuildMemberUpdated = "GuildMemberUpdate",

	Interaction = "Interaction"
}

export type DiscordEvents = "Ready"
	| "Message"
	| "MessageChanged"
	| "MessageDeleted"
	| "MessageDeleteBulk"
	| "ChannelCreate"
	| "ChannelUpdate"
	| "ChannelDelete"
	| "UserUpdate"
	| "ChannelPinsUpdate"
	| "GuildCreate"
	| "GuildUpdate"
	| "GuildDelete"
	| "GuildBanAdded"
	| "GuildBanRemoved"
	| "GuildMemberJoined"
	| "GuildMemberRemove"
	| "GuildMemberUpdate"
	| "Interaction"

return DiscordEvents