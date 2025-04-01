--[=[
	@class Classes.ActivityParty
	@__index Prototype

	Implementation of the Discord ActivityParty class in Luau

	https://discord.com/developers/docs/topics/gateway-events#activity-object-activity-party
]=]

local apiTypes = require("../../lune_packages/api_types")

local ActivityParty = {}

ActivityParty.Interface = {}
ActivityParty.Prototype = {}

--[=[
	@within Classes.ActivityParty
	@private

	Responsible for constructing this class.
]=]
function ActivityParty.Interface.new(id: apiTypes.Snowflake, currentSize: number, maxSize: number): ActivityParty
	local self = setmetatable(
		{
			--[=[
				@prop id string
				@within Classes.ActivityParty
				
				The unique identifier for this activity party
			]=]
			id = id,

			--[=[
				@prop currentSize number
				@within Classes.ActivityParty
				
				The current size of the party
			]=]
			currentSize = currentSize,

			--[=[
				@prop maxSize number
				@within Classes.ActivityParty
				
				The maximum size the party can be
			]=]
			maxSize = maxSize,
		} :: ActivityParty,
		{ __index = ActivityParty.Prototype }
	)

	return self
end

export type ActivityParty = typeof(ActivityParty.Prototype) & {
	id: apiTypes.Snowflake,

	currentSize: number,
	maxSize: number,
}

return ActivityParty.Interface
