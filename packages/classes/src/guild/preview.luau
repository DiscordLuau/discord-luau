--[[
	Implementation of the Discord Guild Preview class in Luau

	https://discord.com/developers/docs/resources/guild#guild-preview-object
]]

local apiTypes = require("../../lune_packages/api_types")

local emojiObject = require("../emoji")
local stickerObject = require("../sticker")

local Preview = {}

Preview.Interface = {}
Preview.Prototype = {}

function Preview.Prototype.sync(self: Preview, previewData: apiTypes.GuildPreviewObject)
	local emojiArray = {}
	local stickerArray = {}

	for _, emojiData in next, previewData.emojis or {} do
		table.insert(emojiArray, emojiObject.new(emojiData))
	end

	for _, stickerData in next, previewData.stickers or {} do
		table.insert(stickerArray, stickerObject.new(stickerData))
	end

	self.id = previewData.id
	self.name = previewData.name
	self.icon = previewData.icon
	self.splash = previewData.splash
	self.discoverySplash = previewData.discovery_splash
	self.emojis = emojiArray
	self.features = previewData.features
	self.approximateMemberCount = previewData.approximate_member_count
	self.approximatePresenceCount = previewData.approximate_presence_count
	self.description = previewData.description
	self.stickers = stickerArray
end

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
