local apiTypes = require("@api-types/apiTypes")

local ActivityTimestamp = {}

ActivityTimestamp.Interface = {}
ActivityTimestamp.Prototype = {}

function ActivityTimestamp.Prototype.sync(self: ActivityTimestamp, emojiData: apiTypes.ActivityEmojiObject)
	self.animated = emojiData.animated
	self.name = emojiData.name
end

function ActivityTimestamp.Interface.new(
	id: apiTypes.Snowflake,
	emojiData: apiTypes.ActivityEmojiObject?
): ActivityTimestamp
	local self = setmetatable(
		{
			id = id,
		} :: ActivityTimestamp,
		{ __index = ActivityTimestamp.Prototype }
	)

	if emojiData then
		self:sync(emojiData)
	end

	return self
end

export type ActivityTimestamp = typeof(ActivityTimestamp.Prototype) & {
	id: apiTypes.Snowflake,
	name: string,
	animated: boolean?,
}

return ActivityTimestamp.Interface
