--[=[
	@class Bit

	A Bit wrapper library that supports both 64-bit integers and 32-bit integers. 
	Primarily required in the calculation for snowflake IDs that the Discord API will give us.
]=]

local Bit64 = require("@self/bit64")
local Bit = {}

--[=[
	@within Bit

	Returns true if the given value is a 32-bit integer.
]=]
function Bit.is32Bit(value: number): boolean
	return value >= 0 and value <= 0xFFFFFFFF
end

--[=[
	@within Bit

	Binary NOT operation for integers
]=]
function Bit.bnot(value: number): number
	if Bit.is32Bit(value) then
		return bit32.bnot(value)
	else
		return Bit64.bnot(value)
	end
end

--[=[
	@within Bit

	Binary OR operation for integers
]=]
function Bit.bor(value0: number, value1: number): number
	if Bit.is32Bit(value0) and Bit.is32Bit(value1) then
		return bit32.bor(value0, value1)
	else
		return Bit64.bor(value0, value1)
	end
end

--[=[
	@within Bit

	Binary AND operation for integers
]=]
function Bit.band(value0: number, value1: number): number
	if Bit.is32Bit(value0) and Bit.is32Bit(value1) then
		return bit32.band(value0, value1)
	else
		return Bit64.band(value0, value1)
	end
end

--[=[
	@within Bit

	Binary SHIFT operation for integers
]=]
function Bit.shift(value: number, displacement: number): number
	if Bit.is32Bit(value) then
		if displacement >= 0 then
			return bit32.lshift(value, displacement)
		else
			return bit32.rshift(value, -displacement)
		end
	else
		return Bit64.shift(value, displacement)
	end
end

--[=[
	@within Bit

	Binary LEFT SHIFT operation for integers
]=]
function Bit.lshift(value: number, displacement: number): number
	return Bit.shift(value, displacement)
end

--[=[
	@within Bit

	Binary RIGHT SHIFT operation for integers
]=]
function Bit.rshift(value: number, displacement: number): number
	return Bit.shift(value, -displacement)
end

return Bit
