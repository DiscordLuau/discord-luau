--[=[
	@class Classes.Reaction
	@__index Prototype

	Implementation of the Discord Reaction class in Luau

	https://discord.com/developers/docs/resources/message#reaction-object-reaction-structure
]=]

--[=[
	@prop count number
	@within Classes.Reaction
	The total number of times this reaction has been used.
]=]

--[=[
	@prop countDetails Classes.CountDetails
	@within Classes.Reaction
	Detailed information about the reaction count.
]=]

--[=[
	@prop me boolean
	@within Classes.Reaction
	Whether the current user has used this reaction.
]=]

--[=[
	@prop meBurst boolean
	@within Classes.Reaction
	Whether the current user has used this reaction in burst mode.
]=]

--[=[
	@prop emoji Emoji
	@within Classes.Reaction
	The emoji used for this reaction.
]=]

--[=[
	@prop burstColors { string }
	@within Classes.Reaction
	The colors used for burst reactions.
]=]

local apiTypes = require("../../luau_packages/api_types")

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
	self.count = reactionData.count

	self.countDetails = countDetails.new(reactionData.count_details)

	self.me = reactionData.me

	self.meBurst = reactionData.me_burst

	self.emoji = emoji.new(reactionData.emoji)

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
