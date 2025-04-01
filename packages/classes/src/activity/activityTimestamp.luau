--[=[
	@class Classes.ActivityTimestamp
	@__index Prototype

	Implementation of the Discord ActivityTimestamps class in Luau

	https://discord.com/developers/docs/topics/gateway-events#activity-object-activity-timestamps
]=]

local stdPolyfills = require("../../lune_packages/std_polyfills")

local ActivityTimestamp = {}

ActivityTimestamp.Interface = {}
ActivityTimestamp.Prototype = {}

--[=[
	@within Classes.ActivityTimestamp
	@private

	Responsible for constructing this class.
]=]
function ActivityTimestamp.Interface.new(startTime: number, endTime: number): ActivityTimestamp
	local self = setmetatable(
		{
			--[=[
				@prop startTime std_polyfills.DateTime
				@within Classes.ActivityTimestamp

				The start time of the activity. This represents when the activity began.
			]=]
			startTime = stdPolyfills.datetime.fromUnixTimestamp(startTime),

			--[=[
				@prop endTime std_polyfills.DateTime
				@within Classes.ActivityTimestamp

				The end time of the activity. This represents when the activity will end.
			]=]
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
