--[=[
	@class Classes.GuildPreview
	@__index Prototype

	Implementation of the Discord Guild Preview class in Luau

	https://discord.com/developers/docs/resources/guild#guild-preview-object
]=]

local apiTypes = require("../../lune_packages/api_types")

local emojiObject = require("../emoji")
local stickerObject = require("../sticker")

local Preview = {}

Preview.Interface = {}
Preview.Prototype = {}

--[=[
	@within Classes.GuildPreview
	@private

	Responsible for syncing data to this guild preview object. This is typically called by the API when this object is
	created or updated.
]=]
function Preview.Prototype.sync(self: Preview, previewData: apiTypes.GuildPreviewObject)
	local emojiArray = {}
	local stickerArray = {}

	for _, emojiData in next, previewData.emojis or {} do
		table.insert(emojiArray, emojiObject.new(emojiData))
	end

	for _, stickerData in next, previewData.stickers or {} do
		table.insert(stickerArray, stickerObject.new(stickerData))
	end

	--[=[
		@prop id string
		@within Classes.GuildPreview

		The unique identifier for this guild preview
	]=]
	self.id = previewData.id

	--[=[
		@prop name string
		@within Classes.GuildPreview

		The name of the guild
	]=]
	self.name = previewData.name

	--[=[
		@prop icon string?
		@within Classes.GuildPreview

		The icon hash of the guild
	]=]
	self.icon = previewData.icon

	--[=[
		@prop splash string?
		@within Classes.GuildPreview

		The splash hash of the guild
	]=]
	self.splash = previewData.splash

	--[=[
		@prop discoverySplash string?
		@within Classes.GuildPreview

		The discovery splash hash of the guild
	]=]
	self.discoverySplash = previewData.discovery_splash

	--[=[
		@prop emojis {Classes.Emoji}
		@within Classes.GuildPreview

		Array of custom emoji objects for this guild
	]=]
	self.emojis = emojiArray

	--[=[
		@prop features {api_types.GuildFeature}
		@within Classes.GuildPreview

		Array of guild feature strings
	]=]
	self.features = previewData.features

	--[=[
		@prop approximateMemberCount number
		@within Classes.GuildPreview

		Approximate number of members in this guild
	]=]
	self.approximateMemberCount = previewData.approximate_member_count

	--[=[
		@prop approximatePresenceCount number
		@within Classes.GuildPreview

		Approximate number of online members in this guild
	]=]
	self.approximatePresenceCount = previewData.approximate_presence_count

	--[=[
		@prop description string?
		@within Classes.GuildPreview

		The description of the guild
	]=]
	self.description = previewData.description

	--[=[
		@prop stickers {Classes.Sticker}
		@within Classes.GuildPreview

		Array of custom sticker objects for this guild
	]=]
	self.stickers = stickerArray
end

--[=[
	@within Classes.GuildPreview
	@private

	Responsible for constructing this class.
]=]
function Preview.Interface.new(previewData: apiTypes.GuildPreviewObject): Preview
	local self = setmetatable({} :: Preview, { __index = Preview.Prototype })

	self:sync(previewData)

	return self
end

export type Preview = typeof(Preview.Prototype) & {
	id: apiTypes.Snowflake,
	name: string,
	icon: string?,
	splash: string?,
	discoverySplash: string?,
	emojis: { emojiObject.Emoji },
	features: { apiTypes.GuildFeature },
	approximateMemberCount: number,
	approximatePresenceCount: number,
	description: string?,
	stickers: { stickerObject.Sticker },
}

return Preview.Interface
