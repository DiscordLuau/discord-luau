--[[
	Implementation of the Discord Emoji class in Luau

	https://discord.com/developers/docs/resources/emoji#emoji-resource
]]

local apiTypes = require("../lune_packages/api_types")

local user = require("./user")

local Emoji = {}

Emoji.Interface = {}
Emoji.Prototype = {}

function Emoji.Prototype.sync(self: Emoji, emojiData: apiTypes.EmojiObject)
	self.roles = emojiData.roles

	self.id = emojiData.id
	self.name = emojiData.name
	self.user = emojiData.user and user.new(emojiData.user)
	self.requireColons = emojiData.require_colons
	self.managed = emojiData.managed
	self.animated = emojiData.animated
	self.available = emojiData.available
end

function Emoji.Interface.new(emojiData: apiTypes.EmojiObject): Emoji
	local self = setmetatable({} :: Emoji, { __index = Emoji.Prototype })

	self:sync(emojiData)

	return self
end

export type Emoji = typeof(Emoji.Prototype) & {
	id: apiTypes.Snowflake?,
	roles: { apiTypes.Snowflake }?,
	name: string?,
	user: user.User?,
	requireColons: boolean?,
	managed: boolean?,
	animated: boolean?,
	available: boolean?,
}

return Emoji.Interface
