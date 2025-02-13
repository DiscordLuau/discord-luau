--[[
	Implementation of the Discord Reaction class in Luau

	https://discord.com/developers/docs/resources/message#reaction-object-reaction-structure
]]

local apiTypes = require("../../lune_packages/api_types")

local countDetails = require("./countDetails")
local emoji = require("../emoji")

local Reaction = {}

Reaction.Interface = {}
Reaction.Prototype = {}

function Reaction.Prototype.sync(self: Reaction, reactionData: apiTypes.ReactionObject)
	self.count = reactionData.count
	self.countDetails = countDetails.new(reactionData.count_details)
	self.me = reactionData.me
	self.meBurst = reactionData.me_burst
	self.emoji = emoji.new(reactionData.emoji)
	self.burstColors = reactionData.burst_colors
end

function Reaction.Interface.new(reactionData: apiTypes.ReactionObject): Reaction
	local self = setmetatable({} :: Reaction, { __index = Reaction.Prototype })

	self:sync(reactionData)

	return self
end

export type Reaction = typeof(Reaction.Prototype) & {
	count: number,
	countDetails: countDetails.CountDetails,
	me: boolean,
	meBurst: boolean,
	emoji: emoji.Emoji,
	burstColors: { string },
}

return Reaction.Interface
