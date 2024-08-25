--[[
	Implementation of the Discord StickerItem class in Luau

	https://discord.com/developers/docs/resources/sticker#sticker-item-object
]]

local apiTypes = require("@api-types/apiTypes")
local stickerTypes = require("@api-types/sticker")

local StickerItem = {}

StickerItem.Interface = {}
StickerItem.Prototype = {}

function StickerItem.Prototype.sync(self: StickerItem, stickerData: apiTypes.SitckerItemObject)
	self.id = stickerData.id
	self.name = stickerData.name
	self.formatType = (
		stickerData.format_type == 1 and "PNG"
		or stickerData.format_type == 2 and "APNG"
		or stickerData.format_type == 3 and "LOTTIE"
		or stickerData.format_type == 4 and "GIF"
	) :: stickerTypes.StickerFormatType
end

function StickerItem.Interface.new(stickerData: apiTypes.SitckerItemObject): StickerItem
	local self = setmetatable({} :: StickerItem, { __index = StickerItem.Prototype })

	self:sync(stickerData)

	return self
end

export type StickerItem = typeof(StickerItem.Prototype) & {
	id: apiTypes.Snowflake,
	name: string,
	formatType: stickerTypes.StickerFormatType,
}

return StickerItem.Interface
