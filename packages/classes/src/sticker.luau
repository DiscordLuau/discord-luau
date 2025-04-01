--[=[
	@class Classes.Sticker
	@__index Prototype

	Implementation of the Discord Sticker class in Luau

	https://discord.com/developers/docs/resources/sticker#sticker-object
]=]

local apiTypes = require("../lune_packages/api_types")

local user = require("./user")

local Sticker = {}

Sticker.Interface = {}
Sticker.Prototype = {}

--[=[
	@within Classes.Sticker
	@private

	Responsible for syncing data to this sticker object. This is typically called by the API when this object is
	created or updated.
]=]
function Sticker.Prototype.sync(self: Sticker, stickerData: apiTypes.StickerObject)
	--[=[
		@prop id string
		@within Classes.Sticker
		The unique identifier for this sticker.
	]=]
	self.id = stickerData.id

	--[=[
		@prop packId string?
		@within Classes.Sticker
		The ID of the sticker pack this sticker belongs to.
	]=]
	self.packId = stickerData.pack_id

	--[=[
		@prop name string
		@within Classes.Sticker
		The name of this sticker.
	]=]
	self.name = stickerData.name

	--[=[
		@prop description string?
		@within Classes.Sticker
		The description of this sticker.
	]=]
	self.description = stickerData.description

	--[=[
		@prop tags string?
		@within Classes.Sticker
		The tags associated with this sticker.
	]=]
	self.tags = stickerData.tags

	--[=[
		@prop type apiTypes.StickerType
		@within Classes.Sticker
		The type of this sticker.
	]=]
	self.type = apiTypes.sticker.StickerTypes[stickerData.type]

	--[=[
		@prop formatType apiTypes.StickerFormatType
		@within Classes.Sticker
		The format type of this sticker.
	]=]
	self.formatType = apiTypes.sticker.StickerFormatType[stickerData.format_type]

	--[=[
		@prop available boolean?
		@within Classes.Sticker
		Whether this sticker is available for use.
	]=]
	self.available = stickerData.available

	--[=[
		@prop guildId string?
		@within Classes.Sticker
		The ID of the guild this sticker belongs to.
	]=]
	self.guildId = stickerData.guild_id

	--[=[
		@prop user Classes.User?
		@within Classes.Sticker
		The user who uploaded this sticker.
	]=]
	self.user = stickerData.user and user.new(stickerData.user)

	--[=[
		@prop sortValue number?
		@within Classes.Sticker
		The sort value of this sticker within its pack.
	]=]
	self.sortValue = stickerData.sort_value
end

--[=[
	@within Classes.Sticker
	@private

	Responsible for constructing this class.
]=]
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
	type: apiTypes.StickerType,
	formatType: apiTypes.StickerFormatType,
	available: boolean?,
	guildId: apiTypes.Snowflake?,
	user: user.User?,
	sortValue: number?,
}

return Sticker.Interface
