local reflect = require("@utils/table/reflect")

local ChannelTypes = table.freeze(reflect({
	GuildText = 0,
	DM = 1,
	GuildVoice = 2,
	GroupDM = 3,
	GuildCategory = 4,
	GuildAnnouncement = 5,
	AnnouncementThread = 10,
	PublicThread = 11,
	PrivateThread = 12,
	GuildStageVoice = 13,
	GuildDirectory = 14,
	GuildForum = 15,
	GuildMedia = 16,
}))

local MediaSortOrder = table.freeze(reflect({
	LatestActivity = 0,
	CreationDate = 1,
}))

local ForumSortOrder = table.freeze(reflect({
	LatestActivity = 0,
	CreationDate = 1,
}))

local ForumLayout = table.freeze(reflect({
	NotSet = 0,
	ListView = 1,
	GalleryView = 2,
}))

local VideoQualityMode = table.freeze(reflect({
	Auto = 1,
	Full = 2,
}))

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

return {
	ChannelTypes = ChannelTypes,
	MediaSortOrder = MediaSortOrder,
	ForumSortOrder = ForumSortOrder,
	ForumLayout = ForumLayout,
	VideoQualityMode = VideoQualityMode,
}
