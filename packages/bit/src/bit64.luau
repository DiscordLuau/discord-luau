--[[
	An optimized 64-bit library to provide 64-bit binary operations in Luau
	using 32-bit operations and `bit32` for improved performance.
]]
local Bit64 = {}

--[[
	Splits a 64-bit integer into high and low 32-bit integers
]]
local function split64(value: number): (number, number)
	local low = bit32.band(value, 0xFFFFFFFF)
	local high = math.floor(value / 4294967296)

	return low, high
end

--[[
	Combines high and low 32-bit integers into a 64-bit integer
]]
local function combine64(low: number, high: number): number
	return (high * 4294967296) + low
end

--[[
	Binary NOT operation
]]
function Bit64.bnot(value: number): number
	local low, high = split64(value)
	local newLow = bit32.bnot(low)
	local newHigh = bit32.bnot(high)

	return combine64(newLow, newHigh)
end

--[[
	Binary OR operation
]]
function Bit64.bor(value0: number, value1: number): number
	local low0, high0 = split64(value0)
	local low1, high1 = split64(value1)
	local newLow = bit32.bor(low0, low1)
	local newHigh = bit32.bor(high0, high1)

	return combine64(newLow, newHigh)
end

--[[
	Binary AND operation
]]
function Bit64.band(value0: number, value1: number): number
	local low0, high0 = split64(value0)
	local low1, high1 = split64(value1)
	local newLow = bit32.band(low0, low1)
	local newHigh = bit32.band(high0, high1)

	return combine64(newLow, newHigh)
end

--[[
	Binary SHIFT operation
]]
function Bit64.shift(value: number, displacement: number): number
	if displacement == 0 then
		return value
	end

	local low, high = split64(value)

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

	return combine64(low, high)
end

return Bit64
