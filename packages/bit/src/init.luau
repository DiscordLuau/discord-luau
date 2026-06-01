--[=[
	@class Bit

	A Bit wrapper library that supports 64-bit integers represented as decimal strings.
	Primarily required in the calculation for snowflake IDs that the Discord API will give us.
]=]

local int64 = require("@self/../luau_packages/int64")

local Bit = {}

--[=[
	@within Bit

	Binary NOT operation for integers
]=]
function Bit.bnot(value: string): string
	return int64.to_dec_string(int64.bnot(int64.from_dec_string(value)))
end

--[=[
	@within Bit

	Binary OR operation for integers
]=]
function Bit.bor(value0: string, value1: string): string
	return int64.to_dec_string(int64.bor(int64.from_dec_string(value0), int64.from_dec_string(value1)))
end

--[=[
	@within Bit

	Binary AND operation for integers
]=]
function Bit.band(value0: string, value1: string): string
	return int64.to_dec_string(int64.band(int64.from_dec_string(value0), int64.from_dec_string(value1)))
end

--[=[
	@within Bit

	Binary SHIFT operation for integers. Positive displacement = left shift, negative = right shift.
]=]
function Bit.shift(value: string, displacement: number): string
	if displacement == 0 then
		return value
	elseif displacement > 0 then
		return int64.to_dec_string(int64.lshift(int64.from_dec_string(value), displacement))
	else
		return int64.to_dec_string(int64.rshift(int64.from_dec_string(value), -displacement))
	end
end

--[=[
	@within Bit

	Binary LEFT SHIFT operation for integers
]=]
function Bit.lshift(value: string, displacement: number): string
	return Bit.shift(value, displacement)
end

--[=[
	@within Bit

	Binary RIGHT SHIFT operation for integers
]=]
function Bit.rshift(value: string, displacement: number): string
	return Bit.shift(value, -displacement)
end

return Bit
