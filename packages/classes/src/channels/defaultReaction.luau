--[=[
	@class Classes.DefaultReaction
	@__index Prototype

	Implementation of the Discord DefaultReaction class in Luau

	https://discord.com/developers/docs/resources/channel#default-reaction-object
]=]

local apiTypes = require("../../lune_packages/api_types")

local DefaultReaction = {}

DefaultReaction.Interface = {}
DefaultReaction.Prototype = {}

--[=[
	@within Classes.DefaultReaction
	@private

	Responsible for syncing data to this default reaction object. This is typically called by the API when this object is
	created or updated.
]=]
function DefaultReaction.Prototype.sync(self: DefaultReaction, DefaultReactionData: apiTypes.DefaultReactionObject)
	--[=[
		@prop emojiId string?
		@within Classes.DefaultReaction

		The ID of the emoji to use as the default reaction
	]=]
	self.emojiId = DefaultReactionData.emoji_id

	--[=[
		@prop emojiName string?
		@within Classes.DefaultReaction

		The name of the emoji to use as the default reaction
	]=]
	self.emojiName = DefaultReactionData.emoji_name
end

--[=[
	@within Classes.DefaultReaction
	@private

	Responsible for constructing this class.
]=]
function DefaultReaction.Interface.new(DefaultReactionData: apiTypes.DefaultReactionObject): DefaultReaction
	local self = setmetatable({} :: DefaultReaction, { __index = DefaultReaction.Prototype })

	self:sync(DefaultReactionData)

	return self
end

export type DefaultReaction = typeof(DefaultReaction.Prototype) & {
	emojiId: string?,
	emojiName: string?,
}

return DefaultReaction.Interface
