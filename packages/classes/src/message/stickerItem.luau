--[=[
	@class Classes.StickerItem
	@__index Prototype

	Implementation of the Discord StickerItem class in Luau

	https://discord.com/developers/docs/resources/sticker#sticker-item-object
]=]

local apiTypes = require("../../lune_packages/api_types")

local StickerItem = {}

StickerItem.Interface = {}
StickerItem.Prototype = {}

--[=[
	@within Classes.StickerItem
	@private

	Responsible for syncing data to this sticker item object. This is typically called by the API when this object is
	created or updated.
]=]
function StickerItem.Prototype.sync(self: StickerItem, stickerData: apiTypes.SitckerItemObject)
	--[=[
		@prop id string
		@within Classes.StickerItem
		The unique identifier for this sticker.
	]=]
	self.id = stickerData.id

	--[=[
		@prop name string
		@within Classes.StickerItem
		The name of this sticker.
	]=]
	self.name = stickerData.name

	--[=[
		@prop formatType string
		@within Classes.StickerItem
		The format type of this sticker.
	]=]
	self.formatType = apiTypes.sticker.StickerFormatTypes[stickerData.format_type]
end

--[=[
	@within Classes.StickerItem
	@private

	Responsible for constructing this class.
]=]
function StickerItem.Interface.new(stickerData: apiTypes.SitckerItemObject): StickerItem
	local self = setmetatable({} :: StickerItem, { __index = StickerItem.Prototype })

	self:sync(stickerData)

	return self
end

export type StickerItem = typeof(StickerItem.Prototype) & {
	id: apiTypes.Snowflake,
	name: string,
	formatType: apiTypes.StickerFormatType,
}

return StickerItem.Interface
