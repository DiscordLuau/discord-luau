--[=[
	@class Types.permission
]=]

local util = require("../lune_packages/util")

local bit = require("../luau_packages/bit")

local Permissions = table.freeze(util.tableReflect({
	CreateInstantInvite = bit.lshift(1, 0),
	KickMembers = bit.lshift(1, 1),
	BanMembers = bit.lshift(1, 2),
	Administrator = bit.lshift(1, 3),
	ManageChannels = bit.lshift(1, 4),
	ManageGuild = bit.lshift(1, 5),
	AddReactions = bit.lshift(1, 6),
	ViewAuditLog = bit.lshift(1, 7),
	PrioritySpeaker = bit.lshift(1, 8),
	Stream = bit.lshift(1, 9),
	ViewChannel = bit.lshift(1, 10),
	SendMessages = bit.lshift(1, 11),
	SendTTSMessages = bit.lshift(1, 12),
	ManageMessages = bit.lshift(1, 13),
	EmbedLinks = bit.lshift(1, 14),
	AttachFiles = bit.lshift(1, 15),
	ReadMessageHistory = bit.lshift(1, 16),
	MentionEveryone = bit.lshift(1, 17),
	UseExternalEmojis = bit.lshift(1, 18),
	ViewGuildInsights = bit.lshift(1, 19),
	Connect = bit.lshift(1, 20),
	Speak = bit.lshift(1, 21),
	MuteMembers = bit.lshift(1, 22),
	DeafenMembers = bit.lshift(1, 23),
	MoveMembers = bit.lshift(1, 24),
	UseVAD = bit.lshift(1, 25),
	ChangeNickname = bit.lshift(1, 26),
	ManageNicknames = bit.lshift(1, 27),
	ManageRoles = bit.lshift(1, 28),
	ManageWebhooks = bit.lshift(1, 29),
	ManageGuildExpressions = bit.lshift(1, 30),
	UseApplicationCommands = bit.lshift(1, 31),
	RequestToSpeak = bit.lshift(1, 32),
	ManageEvents = bit.lshift(1, 33),
	ManageThreads = bit.lshift(1, 34),
	CreatePublicThreads = bit.lshift(1, 35),
	CreatePrivateThreads = bit.lshift(1, 36),
	UseExternalStickers = bit.lshift(1, 37),
	SendMessagesInThreads = bit.lshift(1, 38),
	UseEmbeddedActivities = bit.lshift(1, 39),
	ModerateMembers = bit.lshift(1, 40),
	ViewCreatorMonetizationAnalytics = bit.lshift(1, 41),
	UseSoundboard = bit.lshift(1, 42),
	UseExternalSounds = bit.lshift(1, 45),
	SendVoiceMessages = bit.lshift(1, 46),
	SendPolls = bit.lshift(1, 49),
	UseExternalApps = bit.lshift(1, 50),
}))

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

return {
	Permissions = Permissions,
}
