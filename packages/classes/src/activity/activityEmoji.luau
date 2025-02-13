--[[
	Implementation of the Discord ActivityEmoji class in Luau

	https://discord.com/developers/docs/topics/gateway-events#activity-object-activity-emoji
]]

local apiTypes = require("../../lune_packages/api_types")

local ActivityEmoji = {}

ActivityEmoji.Interface = {}
ActivityEmoji.Prototype = {}

function ActivityEmoji.Prototype.sync(self: ActivityEmoji, emojiData: apiTypes.ActivityEmojiObject)
	self.animated = emojiData.animated
	self.name = emojiData.name
end

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
