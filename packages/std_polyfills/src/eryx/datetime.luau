local date = require("@eryx/date")

local datetime = {}

local EPOCH = date.fromTimestamp(0)

-- Duration.totalSeconds and .totalMilliseconds are number properties (not methods).
local function wrap(dt)
	local diff = dt:diff(EPOCH)
	local totalMs = diff.totalMilliseconds

	return {
		unixTimestamp = math.floor(diff.totalSeconds),
		unixTimestampMillis = math.floor(totalMs),
		toIsoDate = function(_self: any): string
			return dt:toIsoString()
		end,
	}
end

function datetime.now()
	return wrap(date.now())
end

function datetime.fromUnixTimestamp(unixTimestamp: number)
	return wrap(date.fromTimestamp(unixTimestamp))
end

function datetime.fromIsoDate(isoDate: string)
	-- date.fromIso rejects the "Z" suffix; normalize to "+00:00"
	local normalized = string.gsub(isoDate, "Z$", "+00:00")
	return wrap(date.fromIso(normalized))
end

return datetime
