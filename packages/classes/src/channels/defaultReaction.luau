--[=[
	@class Classes.Channels.DefaultReaction
	@__index Prototype

	Implementation of the Discord DefaultReaction class in Luau

	https://discord.com/developers/docs/resources/channel#default-reaction-object
]=]

--[=[
	@prop emojiId string?
	@within Classes.Channels.DefaultReaction

	The ID of the emoji to use as the default reaction
]=]

--[=[
	@prop emojiName string?
	@within Classes.Channels.DefaultReaction

	The name of the emoji to use as the default reaction
]=]

local apiTypes = require("../../luau_packages/api_types")

local DefaultReaction = {}

DefaultReaction.Interface = {}
DefaultReaction.Prototype = {}

--[=[
	@within Classes.Channels.DefaultReaction
	@private

	Responsible for syncing data to this default reaction object. This is typically called by the API when this object is
	created or updated.
]=]
function DefaultReaction.Prototype.sync(self: DefaultReaction, DefaultReactionData: apiTypes.DefaultReactionObject)
	self.emojiId = DefaultReactionData.emoji_id

	self.emojiName = DefaultReactionData.emoji_name
end

--[=[
	@within Classes.Channels.DefaultReaction
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
