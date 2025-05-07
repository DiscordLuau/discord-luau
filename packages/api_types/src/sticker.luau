--[=[
	@class Types.sticker
]=]

local util = require("../lune_packages/util")

local StickerTypes = table.freeze(util.tableReflect({
	Standard = 1,
	Guild = 2,
}))

local StickerFormatTypes = table.freeze(util.tableReflect({
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
