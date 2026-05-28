--[=[
	@class StdPolyfills.datetime
]=]

local runtime = require("./runtime")

local datetime = {}

--[=[
	@within StdPolyfills.datetime

	Creates a new DateTime from an ISO 8601 date-time string.
]=]
function datetime.fromIsoDate(isoDate: string): DateTime
	local target = runtime.assertRuntime()

	if target == "Lune" then
		return require("./lune/datetime").fromIsoDate(isoDate) :: any
	elseif target == "Zune" then
		return require("./zune/datetime").fromIsoDate(isoDate) :: any
	elseif target == "Roblox" then
		return require("./roblox/datetime").fromIsoDate(isoDate) :: any
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
		return require("./lune/datetime").fromUnixTimestamp(unixTimestamp) :: any
	elseif target == "Zune" then
		return require("./zune/datetime").fromUnixTimestamp(unixTimestamp) :: any
	elseif target == "Roblox" then
		return require("./roblox/datetime").fromUnixTimestamp(unixTimestamp) :: any
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
		return require("./lune/datetime").now() :: any
	elseif target == "Zune" then
		return require("./zune/datetime").now() :: any
	elseif target == "Roblox" then
		return require("./roblox/datetime").now() :: any
	end

	error(`Out of reach`)
end

export type DateTime = {
	unixTimestamp: number,
	unixTimestampMillis: number,

	toIsoDate: (self: DateTime) -> string,
}

return datetime
