--[[
	A library providing bit operations for integers up to 52 bits,
	implemented using two 32-bit halves and `bit32`.

	The upper bound of 52 bits reflects IEEE 754 double precision:
	integers above 2^52 cannot be represented exactly, so results of
	operations on larger values are approximate. All Discord permission
	flags currently fit within bit 52.
]]
local Bit52 = {}

--[[
	Splits a value into high and low 32-bit halves.
]]
local function split(value: number): (number, number)
	local high = math.floor(value / 4294967296)
	local low = value - high * 4294967296

	return low, high
end

--[[
	Combines high and low 32-bit halves back into a single number.
]]
local function combine(low: number, high: number): number
	return (high * 4294967296) + low
end

--[[
	Binary NOT operation
]]
-- Mask to 21 high bits so the result stays below 2^53 and is representable as a double.
-- The high half only needs 21 bits because 32 (low) + 21 (high) covers bits 0-52.
function Bit52.bnot(value: number): number
	local low, high = split(value)
	return combine(bit32.bnot(low), bit32.band(bit32.bnot(high), 0x1FFFFF))
end

--[[
	Binary OR operation
]]
function Bit52.bor(value0: number, value1: number): number
	local low0, high0 = split(value0)
	local low1, high1 = split(value1)

	return combine(bit32.bor(low0, low1), bit32.bor(high0, high1))
end

--[[
	Binary AND operation
]]
function Bit52.band(value0: number, value1: number): number
	local low0, high0 = split(value0)
	local low1, high1 = split(value1)

	return combine(bit32.band(low0, low1), bit32.band(high0, high1))
end

--[[
	Binary SHIFT operation. Positive displacement = left shift, negative = right shift.
]]
function Bit52.shift(value: number, displacement: number): number
	if displacement == 0 then
		return value
	end

	local low, high = split(value)

	if displacement > 0 then
		-- Left shift
		if displacement >= 32 then
			high = bit32.lshift(low, displacement - 32)
			low = 0
		else
			high = bit32.bor(bit32.lshift(high, displacement), bit32.rshift(low, 32 - displacement))
			low = bit32.lshift(low, displacement)
		end
	else
		-- Right shift
		displacement = -displacement
		if displacement >= 32 then
			low = bit32.rshift(high, displacement - 32)
			high = 0
		else
			low = bit32.bor(bit32.rshift(low, displacement), bit32.lshift(high, 32 - displacement))
			high = bit32.rshift(high, displacement)
		end
	end

	low = bit32.band(low, 0xFFFFFFFF)
	high = bit32.band(high, 0xFFFFFFFF)

	return combine(low, high)
end

return Bit52
