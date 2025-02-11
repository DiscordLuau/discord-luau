--[[
	@class Std.DateTime
]]

local Runtime = require("runtime")

local DateTime = {}

function DateTime.fromIsoDate(isoDate: string): DateTime
	local target = Runtime:AssertRuntime()

	if target == "Lune" then
		return require("lune/datetime").fromIsoDate(isoDate) :: any
	end

	error(`Out of reach`)
end

function DateTime.fromUnixTimestamp(unixTimestamp: number): DateTime
	local target = Runtime:AssertRuntime()

	if target == "Lune" then
		return require("lune/datetime").fromUnixTimestamp(unixTimestamp) :: any
	end

	error(`Out of reach`)
end

function DateTime.now(): DateTime
	local target = Runtime:AssertRuntime()

	if target == "Lune" then
		return require("lune/datetime").now() :: any
	end

	error(`Out of reach`)
end

export type DateTime = typeof(DateTime) & {
	unixTimestamp: number,
	unixTimestampMillis: number,
}

return DateTime
