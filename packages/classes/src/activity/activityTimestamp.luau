--[[
	Implementation of the Discord ActivityTimestamps class in Luau

	https://discord.com/developers/docs/topics/gateway-events#activity-object-activity-timestamps
]]

local stdPolyfills = require("../../lune_packages/std_polyfills")

local ActivityTimestamp = {}

ActivityTimestamp.Interface = {}
ActivityTimestamp.Prototype = {}

function ActivityTimestamp.Interface.new(startTime: number, endTime: number): ActivityTimestamp
	local self = setmetatable(
		{
			startTime = stdPolyfills.datetime.fromUnixTimestamp(startTime),
			endTime = stdPolyfills.datetime.fromUnixTimestamp(endTime),
		} :: ActivityTimestamp,
		{ __index = ActivityTimestamp.Prototype }
	)

	return self
end

export type ActivityTimestamp = typeof(ActivityTimestamp.Prototype) & {
	startTime: stdPolyfills.DateTime,
	endTime: stdPolyfills.DateTime,
}

return ActivityTimestamp.Interface
