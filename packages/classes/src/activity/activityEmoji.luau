--[=[
	@class Classes.ActivityEmoji
	@__index Prototype

	Implementation of the Discord ActivityEmoji class in Luau

	https://discord.com/developers/docs/topics/gateway-events#activity-object-activity-emoji
]=]

--[=[
	@prop animated boolean?
	@within Classes.ActivityEmoji
	
	Whether this emoji is animated. This is only present if the emoji is custom.
]=]

--[=[
	@prop name string
	@within Classes.ActivityEmoji
	
	The name of the emoji. For custom emojis this is the name of the emoji, for default emojis this is the unicode character.
]=]

--[=[
	@prop id string
	@within Classes.ActivityEmoji
]=]

local apiTypes = require("../../luau_packages/api_types")

local ActivityEmoji = {}

ActivityEmoji.Interface = {}
ActivityEmoji.Prototype = {}

--[=[
	@within Classes.ActivityEmoji
	@private

	Responsible for syncing data to this activity emoji object. This is typically called by the API when this object is
	created or updated.
]=]
function ActivityEmoji.Prototype.sync(self: ActivityEmoji, emojiData: apiTypes.ActivityEmojiObject)
	self.animated = emojiData.animated

	self.name = emojiData.name
end

--[=[
	@within Classes.ActivityEmoji
	@private

	Responsible for constructing this class.
]=]
function ActivityEmoji.Interface.new(id: apiTypes.Snowflake, emojiData: apiTypes.ActivityEmojiObject?): ActivityEmoji
	local self = setmetatable(
		{
			id = id,
		} :: ActivityEmoji,
		{ __index = ActivityEmoji.Prototype }
	)

	if emojiData then
		self:sync(emojiData)
	end

	return self
end

export type ActivityEmoji = typeof(ActivityEmoji.Prototype) & {
	id: apiTypes.Snowflake,
	name: string,
	animated: boolean?,
}

return ActivityEmoji.Interface
