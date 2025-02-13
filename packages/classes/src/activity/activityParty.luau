--[[
	Implementation of the Discord ActivityParty class in Luau

	https://discord.com/developers/docs/topics/gateway-events#activity-object-activity-party
]]

local apiTypes = require("../../lune_packages/api_types")

local ActivityParty = {}

ActivityParty.Interface = {}
ActivityParty.Prototype = {}

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
