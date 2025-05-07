--[=[
	@class Classes.CountDetails
	@__index Prototype

	Implementation of the Discord CountDetails class in Luau

	https://discord.com/developers/docs/resources/message#reaction-count-details-object
]=]

local apiTypes = require("../../lune_packages/api_types")

local CountDetails = {}

CountDetails.Interface = {}
CountDetails.Prototype = {}

--[=[
	@within Classes.CountDetails
	@private

	Responsible for syncing data to this count details object. This is typically called by the API when this object is
	created or updated.
]=]
function CountDetails.Prototype.sync(self: CountDetails, reactionCountDetailsData: apiTypes.ReactionCountDetailsObject)
	--[=[
		@prop burst number
		@within Classes.CountDetails
		The number of burst reactions.
	]=]
	self.burst = reactionCountDetailsData.burst

	--[=[
		@prop normal number
		@within Classes.CountDetails
		The number of normal reactions.
	]=]
	self.normal = reactionCountDetailsData.normal
end

--[=[
	@within Classes.CountDetails
	@private

	Responsible for constructing this class.
]=]
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
