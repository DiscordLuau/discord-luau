-- selene: allow(undefined_variable)
local datetime = {}

-- Roblox's DateTime uses PascalCase; wrap to match the polyfill's camelCase shape
local function wrap(dt)
	return {
		unixTimestamp = dt.UnixTimestamp,
		unixTimestampMillis = dt.UnixTimestampMillis,

		toIsoDate = function(_self: any): string
			return dt:ToIsoDate()
		end,
	}
end

function datetime.now()
	return wrap(DateTime.now())
end

function datetime.fromUnixTimestamp(unixTimestamp: number)
	return wrap(DateTime.fromUnixTimestamp(unixTimestamp))
end

function datetime.fromIsoDate(isoDate: string)
	return wrap(DateTime.fromIsoDate(isoDate))
end

return datetime
