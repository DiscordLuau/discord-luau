--[[
	Implementation of a discord default reaction object as a luau builder.	

	An object that specifies the emoji to use as the default way to react to a forum post. Exactly one of emoji_id and emoji_name must be set.

	https://discord.com/developers/docs/resources/channel#default-reaction-object
]]

local apiTypes = require("@api-types/apiTypes")

local DefaultReactionBuilder = {}

DefaultReactionBuilder.Prototype = {}
DefaultReactionBuilder.Interface = {}

--[[
	Responsible for buillding the default reaction object that the Discord API can understand.
]]
function DefaultReactionBuilder.Prototype.build(self: DefaultReactionBuilder): apiTypes.DefaultReactionObject
	return {
		emoji_id = self.emojiId,
		emoji_name = self.emojiName,
	}
end

--[[
	Constructor for the Discord Default Reaction Builder.

	```lua
	local defaultReaction = DefaultReactionBuilder.new("000000000000000000", "secret-emoji"):build()
	```
]]
function DefaultReactionBuilder.Interface.new(resource: {
	emojiId: apiTypes.Snowflake?,
	emojiName: string?,
}): DefaultReactionBuilder
	local self = setmetatable(
		{
			emojiId = resource.emojiId,
			emojiName = resource.emojiName,
		} :: DefaultReactionBuilder,
		{ __index = DefaultReactionBuilder.Prototype }
	)

	return self
end

export type DefaultReactionBuilder = typeof(DefaultReactionBuilder.Prototype) & {
	emojiId: apiTypes.Snowflake?,
	emojiName: string?,
}

return DefaultReactionBuilder.Interface
