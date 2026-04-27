--[=[
	@class Classes.Activity.Party
	@__index Prototype

	Implementation of the Discord ActivityParty class in Luau

	https://discord.com/developers/docs/topics/gateway-events#activity-object-activity-party
]=]

--[=[
	@prop id string
	@within Classes.Activity.Party
	
	The unique identifier for this activity party
]=]

--[=[
	@prop currentSize number
	@within Classes.Activity.Party
	
	The current size of the party
]=]

--[=[
	@prop maxSize number
	@within Classes.Activity.Party
	
	The maximum size the party can be
]=]

local apiTypes = require("../../luau_packages/api_types")

local ActivityParty = {}

ActivityParty.Interface = {}
ActivityParty.Prototype = {}

--[=[
	@within Classes.Activity.Party
	@private

	Responsible for constructing this class.
]=]
function ActivityParty.Interface.new(id: apiTypes.Snowflake, currentSize: number, maxSize: number): ActivityParty
	local self = setmetatable(
		{
			id = id,

			currentSize = currentSize,

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
