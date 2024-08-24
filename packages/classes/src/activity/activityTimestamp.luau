--[[
	Implementation of the Discord ActivityTimestamps class in Luau

	https://discord.com/developers/docs/topics/gateway-events#activity-object-activity-timestamps
]]

local datetime = require("@std-polyfills/datetime")

local ActivityTimestamp = {}

ActivityTimestamp.Interface = {}
ActivityTimestamp.Prototype = {}

function ActivityTimestamp.Interface.new(startTime: number, endTime: number): ActivityTimestamp
	local self = setmetatable(
		{
			startTime = datetime.fromUnixTimestamp(startTime),
			endTime = datetime.fromUnixTimestamp(endTime),
		} :: ActivityTimestamp,
		{ __index = ActivityTimestamp.Prototype }
	)

	return self
end

export type ActivityTimestamp = typeof(ActivityTimestamp.Prototype) & {
	startTime: datetime.DateTime,
	endTime: datetime.DateTime,
}

return ActivityTimestamp.Interface
