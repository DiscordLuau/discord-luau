--[=[
	@class Classes.Reaction
	@__index Prototype

	Implementation of the Discord Reaction class in Luau

	https://discord.com/developers/docs/resources/message#reaction-object-reaction-structure
]=]

local apiTypes = require("../../lune_packages/api_types")

local countDetails = require("./countDetails")
local emoji = require("../emoji")

local Reaction = {}

Reaction.Interface = {}
Reaction.Prototype = {}

--[=[
	@within Classes.Reaction
	@private

	Responsible for syncing data to this reaction object. This is typically called by the API when this object is
	created or updated.
]=]
function Reaction.Prototype.sync(self: Reaction, reactionData: apiTypes.ReactionObject)
	--[=[
		@prop count number
		@within Classes.Reaction
		The total number of times this reaction has been used.
	]=]
	self.count = reactionData.count

	--[=[
		@prop countDetails Classes.CountDetails
		@within Classes.Reaction
		Detailed information about the reaction count.
	]=]
	self.countDetails = countDetails.new(reactionData.count_details)

	--[=[
		@prop me boolean
		@within Classes.Reaction
		Whether the current user has used this reaction.
	]=]
	self.me = reactionData.me

	--[=[
		@prop meBurst boolean
		@within Classes.Reaction
		Whether the current user has used this reaction in burst mode.
	]=]
	self.meBurst = reactionData.me_burst

	--[=[
		@prop emoji Emoji
		@within Classes.Reaction
		The emoji used for this reaction.
	]=]
	self.emoji = emoji.new(reactionData.emoji)

	--[=[
		@prop burstColors { string }
		@within Classes.Reaction
		The colors used for burst reactions.
	]=]
	self.burstColors = reactionData.burst_colors
end

--[=[
	@within Classes.Reaction
	@private

	Responsible for constructing this class.
]=]
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
