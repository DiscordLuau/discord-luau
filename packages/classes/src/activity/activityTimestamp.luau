--[=[
	@class Classes.Activity.Timestamp
	@__index Prototype

	Implementation of the Discord ActivityTimestamps class in Luau

	https://discord.com/developers/docs/topics/gateway-events#activity-object-activity-timestamps
]=]

--[=[
	@prop startTime std_polyfills.DateTime
	@within Classes.Activity.Timestamp

	The start time of the activity. This represents when the activity began.
]=]

--[=[
	@prop endTime std_polyfills.DateTime
	@within Classes.Activity.Timestamp

	The end time of the activity. This represents when the activity will end.
]=]

local stdPolyfills = require("../../luau_packages/std_polyfills")

local ActivityTimestamp = {}

ActivityTimestamp.Interface = {}
ActivityTimestamp.Prototype = {}

--[=[
	@within Classes.Activity.Timestamp
	@private

	Responsible for constructing this class.
]=]
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
