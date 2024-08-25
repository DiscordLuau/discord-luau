export type ChannelType =
	"GuildText"
	| "DM"
	| "GuildVoice"
	| "GroupDM"
	| "GuildCategory"
	| "GuildAnnouncement"
	| "AnnouncementThread"
	| "PublicThread"
	| "PrivateThread"
	| "GuildStageVoice"
	| "GuildDirectory"
	| "GuildForum"
	| "GuildMedia"

export type MediaSortOrder = "LatestActivity" | "CreationDate"
export type ForumSortOrder = "LatestActivity" | "CreationDate"
export type ForumLayout = "NotSet" | "ListView" | "GalleryView"

export type VideoQualityMode = "Auto" | "Full"

return "DISCORD_V10_CHANNEL_TYPES"
