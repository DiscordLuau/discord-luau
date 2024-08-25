local permissions = {
	CreateInstantInvite = bit32.lshift(1, 0),
	KickMembers = bit32.lshift(1, 1),
	BanMembers = bit32.lshift(1, 2),
	Administrator = bit32.lshift(1, 3),
	ManageChannels = bit32.lshift(1, 4),
	ManageGuild = bit32.lshift(1, 5),
	AddReactions = bit32.lshift(1, 6),
	ViewAuditLog = bit32.lshift(1, 7),
	PrioritySpeaker = bit32.lshift(1, 8),
	Stream = bit32.lshift(1, 9),
	ViewChannel = bit32.lshift(1, 10),
	SendMessages = bit32.lshift(1, 11),
	SendTTSMessages = bit32.lshift(1, 12),
	ManageMessages = bit32.lshift(1, 13),
	EmbedLinks = bit32.lshift(1, 14),
	AttachFiles = bit32.lshift(1, 15),
	ReadMessageHistory = bit32.lshift(1, 16),
	MentionEveryone = bit32.lshift(1, 17),
	UseExternalEmojis = bit32.lshift(1, 18),
	ViewGuildInsights = bit32.lshift(1, 19),
	Connect = bit32.lshift(1, 20),
	Speak = bit32.lshift(1, 21),
	MuteMembers = bit32.lshift(1, 22),
	DeafenMembers = bit32.lshift(1, 23),
	MoveMembers = bit32.lshift(1, 24),
	UseVAD = bit32.lshift(1, 25),
	ChangeNickname = bit32.lshift(1, 26),
	ManageNicknames = bit32.lshift(1, 27),
	ManageRoles = bit32.lshift(1, 28),
	ManageWebhooks = bit32.lshift(1, 29),
	ManageGuildExpressions = bit32.lshift(1, 30),
	UseApplicationCommands = bit32.lshift(1, 31),
	RequestToSpeak = bit32.lshift(1, 32),
	ManageEvents = bit32.lshift(1, 33),
	ManageThreads = bit32.lshift(1, 34),
	CreatePublicThreads = bit32.lshift(1, 35),
	CreatePrivateThreads = bit32.lshift(1, 36),
	UseExternalStickers = bit32.lshift(1, 37),
	SendMessagesInThreads = bit32.lshift(1, 38),
	UseEmbeddedActivities = bit32.lshift(1, 39),
	ModerateMembers = bit32.lshift(1, 40),
	ViewCreatorMonetizationAnalytics = bit32.lshift(1, 41),
	UseSoundboard = bit32.lshift(1, 42),
	UseExternalSounds = bit32.lshift(1, 45),
	SendVoiceMessages = bit32.lshift(1, 46),
	SendPolls = bit32.lshift(1, 49),
	UseExternalApps = bit32.lshift(1, 50),
}

export type Permissions =
	"CreateInstantInvite"
	| "KickMembers"
	| "BanMembers"
	| "Administrator"
	| "ManageChannels"
	| "ManageGuild"
	| "AddReactions"
	| "ViewAuditLog"
	| "PrioritySpeaker"
	| "Stream"
	| "ViewChannel"
	| "SendMessages"
	| "SendTtsMessages"
	| "ManageMessages"
	| "EmbedLinks"
	| "AttachFiles"
	| "ReadMessageHistory"
	| "MentionEveryone"
	| "UseExternalEmojis"
	| "ViewGuildInsights"
	| "Connect"
	| "Speak"
	| "MuteMembers"
	| "DeafenMembers"
	| "MoveMembers"
	| "UseVad"
	| "ChangeNickname"
	| "ManageNicknames"
	| "ManageRoles"
	| "ManageWebhooks"
	| "ManageEmojisAndStickers"
	| "UseApplicationCommands"
	| "RequestToSpeak"
	| "ManageEvents"
	| "ManageThreads"
	| "CreatePublicThreads"
	| "CreatePrivateThreads"
	| "UseExternalStickers"
	| "SendMessagesInThreads"
	| "UseEmbeddedActivities"
	| "ModerateMembers"
	| "ViewCreatorMonetizationAnalytics"
	| "UseSoundboard"
	| "CreateGuildExpressions"
	| "CreateEvents"
	| "UseExternalSounds"
	| "SendVoiceMessages"
	| "SendPolls"
	| "UseExternalApps"

return permissions
