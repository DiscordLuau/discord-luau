--[=[
	@class StdPolyfills.datetime
]=]

local runtime = require("@self/runtime")

local datetime = {}

--[=[
	@within StdPolyfills.datetime

	Creates a new DateTime from an ISO 8601 date-time string.
]=]
function datetime.fromIsoDate(isoDate: string): DateTime
	local target = runtime.assertRuntime()

	if target == "Lune" then
		return require("@self/lune/datetime").fromIsoDate(isoDate) :: any
	end

	error(`Out of reach`)
end

--[=[
	@within StdPolyfills.datetime

	Creates a new DateTime from the given UNIX timestamp.

	This timestamp may contain both a whole and fractional part - where the fractional part denotes milliseconds / nanoseconds.
]=]
function datetime.fromUnixTimestamp(unixTimestamp: number): DateTime
	local target = runtime.assertRuntime()

	if target == "Lune" then
		return require("@self/lune/datetime").fromUnixTimestamp(unixTimestamp) :: any
	end

	error(`Out of reach`)
end

--[=[
	@within StdPolyfills.datetime

	Returns a DateTime representing the current moment in time.
]=]
function datetime.now(): DateTime
	local target = runtime.assertRuntime()

	if target == "Lune" then
		return require("@self/lune/datetime").now() :: any
	end

	error(`Out of reach`)
end

export type DateTime = typeof(datetime) & {
	unixTimestamp: number,
	unixTimestampMillis: number,

	toIsoDate: (self: DateTime) -> string,
}

return datetime
