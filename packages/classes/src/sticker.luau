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

function Sticker.Prototype.sync(self: Sticker, stickerData: apiTypes.StickerObject)
	self.id = stickerData.id
	self.packId = stickerData.pack_id
	self.name = stickerData.name
	self.description = stickerData.description
	self.tags = stickerData.tags
	self.type = stickerTypes.StickerTypes[stickerData.type]
	self.formatType = stickerTypes.StickerFormatTypes[stickerData.format_type]
	self.available = stickerData.available
	self.guildId = stickerData.guild_id
	self.user = stickerData.user and user.new(stickerData.user)
	self.sortValue = stickerData.sort_value
end

function Sticker.Interface.new(stickerData: apiTypes.StickerObject): Sticker
	local self = setmetatable({} :: Sticker, { __index = Sticker.Prototype })

	self:sync(stickerData)

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
