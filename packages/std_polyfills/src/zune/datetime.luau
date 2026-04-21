-- selene: allow(undefined_variable)
local zuneTime = zune.time

local datetime = {}

local function wrapDateTime(dt)
	return {
		unixTimestamp = dt.timestamp,
		unixTimestampMillis = dt.timestamp_millis,
		toIsoDate = function(self)
			return dt:toIsoDate()
		end,
	}
end

function datetime.fromIsoDate(isoDate: string)
	return wrapDateTime(zuneTime.date.fromIsoDate(isoDate))
end

function datetime.fromUnixTimestamp(unixTimestamp: number)
	return wrapDateTime(zuneTime.date.fromUnixTimestamp(unixTimestamp))
end

function datetime.now()
	return wrapDateTime(zuneTime.date.now())
end

return datetime
