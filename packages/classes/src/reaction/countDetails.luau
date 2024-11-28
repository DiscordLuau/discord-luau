--[[
	Implementation of the Discord CountDetails class in Luau

	https://discord.com/developers/docs/resources/message#reaction-count-details-object
]]

local apiTypes = require("../../lune_packages/api_types")

local CountDetails = {}

CountDetails.Interface = {}
CountDetails.Prototype = {}

function CountDetails.Prototype.sync(self: CountDetails, reactionCountDetailsData: apiTypes.ReactionCountDetailsObject)
	self.burst = reactionCountDetailsData.burst
	self.normal = reactionCountDetailsData.normal
end

function CountDetails.Interface.new(reactionCountDetailsData: apiTypes.ReactionCountDetailsObject): CountDetails
	local self = setmetatable({} :: CountDetails, { __index = CountDetails.Prototype })

	self:sync(reactionCountDetailsData)

	return self
end

export type CountDetails = typeof(CountDetails.Prototype) & {
	burst: number,
	normal: number,
}

return CountDetails.Interface
