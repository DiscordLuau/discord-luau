--[[
	Implementation of the Discord Sticker class in Luau

	https://discord.com/developers/docs/resources/sticker#sticker-object
]]

local apiTypes = require("@api-types/apiTypes")
local stickerTypes = require("@api-types/sticker")

local user = require("@classes/user")

local Sticker = {}

Sticker.Interface = {}
Sticker.Prototype = {}

function Sticker.Prototype.sync(self: Sticker, emojiData: apiTypes.StickerObject)
	self.id = emojiData.id
	self.packId = emojiData.pack_id
	self.name = emojiData.name
	self.description = emojiData.description
	self.tags = emojiData.tags
	self.type = (emojiData.type == 1 and "Standard" or "Guild") :: stickerTypes.StickerType
	self.formatType = (
		emojiData.format_type == 1 and "PNG"
		or emojiData.format_type == 2 and "APNG"
		or emojiData.format_type == 3 and "LOTTIE"
		or emojiData.format_type == 4 and "GIF"
		or "Unknown"
	) :: stickerTypes.StickerFormatType
	self.available = emojiData.available
	self.guildId = emojiData.guild_id
	self.user = emojiData.user and user.new(emojiData.user)
	self.sortValue = emojiData.sort_value
end

function Sticker.Interface.new(emojiData: apiTypes.StickerObject): Sticker
	local self = setmetatable({} :: Sticker, { __index = Sticker.Prototype })

	self:sync(emojiData)

	return self
end

export type Sticker = typeof(Sticker.Prototype) & {
	id: apiTypes.Snowflake,
	packId: apiTypes.Snowflake?,
	name: string,
	description: string?,
	tags: string,
	type: stickerTypes.StickerType,
	formatType: stickerTypes.StickerFormatType,
	available: boolean?,
	guildId: apiTypes.Snowflake?,
	user: user.User?,
	sortValue: number?,
}

return Sticker.Interface
