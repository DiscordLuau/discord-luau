local utilities = require("../lune_packages/utilities")

local EmbedType = table.freeze(utilities.table.reflect({
	Rich = "rich",
	Image = "image",
	Video = "video",
	Gifv = "gifv",
	Article = "article",
	Link = "link",
	PollResult = "poll_result",
}))

export type EmbedType = "Rich" | "Image" | "Video" | "Gifv" | "Article" | "Link" | "PollResult"

return {
	EmbedType = EmbedType,
}
