--[=[
	@class Classes.Emoji
	@__index Prototype

	Implementation of the Discord Emoji class in Luau

	https://discord.com/developers/docs/resources/emoji#emoji-resource
]=]

--[=[
	@prop roles { apiTypes.Snowflake }?
	@within Classes.Emoji
	The roles that can use this emoji.
]=]

--[=[
	@prop id apiTypes.Snowflake?
	@within Classes.Emoji
	The unique identifier for this emoji.
]=]

--[=[
	@prop name string?
	@within Classes.Emoji
	The name of this emoji.
]=]

--[=[
	@prop user Classes.User?
	@within Classes.Emoji
	The user who created this emoji.
]=]

--[=[
	@prop requireColons boolean?
	@within Classes.Emoji
	Whether this emoji requires colons to be used.
]=]

--[=[
	@prop managed boolean?
	@within Classes.Emoji
	Whether this emoji is managed by an integration.
]=]

--[=[
	@prop animated boolean?
	@within Classes.Emoji
	Whether this emoji is animated.
]=]

--[=[
	@prop available boolean?
	@within Classes.Emoji
	Whether this emoji is available for use.
]=]

local apiTypes = require("../luau_packages/api_types")

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
	self.roles = emojiData.roles

	self.id = emojiData.id

	self.name = emojiData.name

	self.user = emojiData.user and user.new(emojiData.user)

	self.requireColons = emojiData.require_colons

	self.managed = emojiData.managed

	self.animated = emojiData.animated

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
