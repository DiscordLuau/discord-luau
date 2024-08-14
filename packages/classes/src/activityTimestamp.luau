local ActivityTimestamp = {}

ActivityTimestamp.Interface = {}
ActivityTimestamp.Prototype = {}

function ActivityTimestamp.Interface.new(startTime: number, endTime: number): ActivityTimestamp
	local self = setmetatable(
		{
			startTime = startTime,
			endTime = endTime,
		} :: ActivityTimestamp,
		{ __index = ActivityTimestamp.Prototype }
	)

	return self
end

export type ActivityTimestamp = typeof(ActivityTimestamp.Prototype) & {
	startTime: number,
	endTime: number,
}

return ActivityTimestamp.Interface
