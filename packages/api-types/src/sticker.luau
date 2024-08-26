local reflect = require("@utils/table/reflect")

local StickerTypes = table.freeze(reflect({
	Standard = 1,
	Guild = 2,
}))

local StickerFormatTypes = table.freeze(reflect({
	PNG = 1,
	APNG = 2,
	LOTTIE = 3,
	GIF = 4,
}))

export type StickerType = "Standard" | "Guild"
export type StickerFormatType = "PNG" | "APNG" | "LOTTIE" | "GIF" | "Unknown"

return {
	StickerTypes = StickerTypes,
	StickerFormatTypes = StickerFormatTypes,
}
