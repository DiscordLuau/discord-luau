--[[
	Implementation of the Discord DefaultReaction class in Luau

	https://discord.com/developers/docs/resources/channel#default-reaction-object
]]

local apiTypes = require("../../lune_packages/api_types")

local DefaultReaction = {}

DefaultReaction.Interface = {}
DefaultReaction.Prototype = {}

function DefaultReaction.Prototype.sync(self: DefaultReaction, DefaultReactionData: apiTypes.DefaultReactionObject)
	self.emojiId = DefaultReactionData.emoji_id
	self.emojiName = DefaultReactionData.emoji_name
end

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
