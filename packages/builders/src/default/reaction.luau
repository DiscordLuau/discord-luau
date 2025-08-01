--[=[
	@class Builders.DefaultReaction
	@__index Prototype

	Implementation of a discord default reaction object as a luau builder.	

	An object that specifies the emoji to use as the default way to react to a forum post. Exactly one of emoji_id and emoji_name must be set.

	https://discord.com/developers/docs/resources/channel#default-reaction-object
]=]

local apiTypes = require("../../lune_packages/api_types")

local DefaultReaction = {}

DefaultReaction.Prototype = {}
DefaultReaction.Interface = {}

--[=[
	@within Builders.DefaultReaction

	Responsible for buillding the default reaction object that the Discord API can understand.
]=]
function DefaultReaction.Prototype.build(self: DefaultReaction): JSON
	return {
		emoji_id = self.emojiId,
		emoji_name = self.emojiName,
	}
end

--[=[
	@within Builders.DefaultReaction

	Constructor for the Discord Default Reaction Builder.

	```luau
	local defaultReaction = DefaultReaction.new("000000000000000000", "secret-emoji"):build()
	```
]=]
function DefaultReaction.Interface.new(resource: {
	emojiId: apiTypes.Snowflake?,
	emojiName: string?,
}): DefaultReaction
	local self = setmetatable(
		{
			--[=[
				@prop emojiId string?
				@within Builders.DefaultReaction
				The id of a guild's custom emoji.
			]=]
			emojiId = resource.emojiId,

			--[=[
				@prop emojiName string?
				@within Builders.DefaultReaction
				The unicode character of the emoji.
			]=]
			emojiName = resource.emojiName,
		} :: DefaultReaction,
		{ __index = DefaultReaction.Prototype }
	)

	return self
end

export type DefaultReaction = typeof(DefaultReaction.Prototype) & {
	emojiId: apiTypes.Snowflake?,
	emojiName: string?,
}

export type JSON = typeof(DefaultReaction.Prototype.build(nil :: any))

return DefaultReaction.Interface
