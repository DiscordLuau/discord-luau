--[[
	@class std.datetime
]]

local runtime = require("runtime")

local datetime = {}

function datetime.fromIsoDate(isoDate: string): DateTime
	local target = runtime.assertRuntime()

	if target == "Lune" then
		return require("lune/datetime").fromIsoDate(isoDate) :: any
	end

	error(`Out of reach`)
end

function datetime.fromUnixTimestamp(unixTimestamp: number): DateTime
	local target = runtime.assertRuntime()

	if target == "Lune" then
		return require("lune/datetime").fromUnixTimestamp(unixTimestamp) :: any
	end

	error(`Out of reach`)
end

function datetime.now(): DateTime
	local target = runtime.assertRuntime()

	if target == "Lune" then
		return require("lune/datetime").now() :: any
	end

	error(`Out of reach`)
end

export type DateTime = typeof(datetime) & {
	unixTimestamp: number,
	unixTimestampMillis: number,

	toIsoDate: (self: DateTime) -> string,
}

return datetime
