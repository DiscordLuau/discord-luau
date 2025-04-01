--[=[
	@class Classes.Emoji
	@__index Prototype

	Implementation of the Discord Emoji class in Luau

	https://discord.com/developers/docs/resources/emoji#emoji-resource
]=]

local apiTypes = require("../lune_packages/api_types")

local user = require("./user")

local Emoji = {}

Emoji.Interface = {}
Emoji.Prototype = {}

--[=[
	@within Classes.Emoji
	@private

	Responsible for syncing data to this emoji object. This is typically called by the API when this object is
	created or updated.
]=]
function Emoji.Prototype.sync(self: Emoji, emojiData: apiTypes.EmojiObject)
	--[=[
		@prop roles { apiTypes.Snowflake }?
		@within Classes.Emoji
		The roles that can use this emoji.
	]=]
	self.roles = emojiData.roles

	--[=[
		@prop id apiTypes.Snowflake?
		@within Classes.Emoji
		The unique identifier for this emoji.
	]=]
	self.id = emojiData.id

	--[=[
		@prop name string?
		@within Classes.Emoji
		The name of this emoji.
	]=]
	self.name = emojiData.name

	--[=[
		@prop user Classes.User?
		@within Classes.Emoji
		The user who created this emoji.
	]=]
	self.user = emojiData.user and user.new(emojiData.user)

	--[=[
		@prop requireColons boolean?
		@within Classes.Emoji
		Whether this emoji requires colons to be used.
	]=]
	self.requireColons = emojiData.require_colons

	--[=[
		@prop managed boolean?
		@within Classes.Emoji
		Whether this emoji is managed by an integration.
	]=]
	self.managed = emojiData.managed

	--[=[
		@prop animated boolean?
		@within Classes.Emoji
		Whether this emoji is animated.
	]=]
	self.animated = emojiData.animated

	--[=[
		@prop available boolean?
		@within Classes.Emoji
		Whether this emoji is available for use.
	]=]
	self.available = emojiData.available
end

--[=[
	@within Classes.Emoji
	@private

	Responsible for constructing this class.
]=]
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
