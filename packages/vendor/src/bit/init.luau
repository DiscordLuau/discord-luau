--[[
	A Bit wrapper library that supports both 64 Bit integers and 32 Bit integers. Primarily required in the calculation
	for snowflake IDs that the Discord API will give us.
]]

local MAXIMUM_32BIT_VALUE = 2147483647

local Bit64 = require("bit64")
local Bit32 = bit32

local Bit = {}

--[[
	Binary NOT operation for 64 bit ints
]]
function Bit.bnot(value: number): number
	if value > MAXIMUM_32BIT_VALUE then
		return Bit64.bnot(value)
	else
		return Bit32.bnot(value)
	end
end

--[[
	Binary OR operation for 64 bit ints
]]
function Bit.bor(value0: number, value1: number): number
	if value0 > MAXIMUM_32BIT_VALUE then
		return Bit64.bor(value0, value1)
	else
		return Bit32.bor(value0, value1)
	end
end

--[[
	Binary AND operation for 64 bit ints
]]
function Bit.band(value0: number, value1: number): number
	if value0 > MAXIMUM_32BIT_VALUE then
		return Bit64.band(value0, value1)
	else
		return Bit32.band(value0, value1)
	end
end

--[[
	Binary SHIFT operation for 64 bit ints, disposition is the number of bits to shift by, can support negative values
]]
function Bit.shift(value: number, disposition: number): number
	if value > MAXIMUM_32BIT_VALUE then
		return Bit64.shift(value, disposition)
	else
		if disposition > 0 then
			return Bit32.rshift(value, disposition)
		else
			return Bit32.lshift(value, disposition)
		end
	end
end

--[[
	Binary LEFT SHIFT operation for 64 bit ints
]]
function Bit.lshift(value: number, disposition: number): number
	return Bit.shift(value, disposition)
end

--[[
	Binary RIGHT SHIFT operation for 64 bit ints
]]
function Bit.rshift(value: number, disposition: number): number
	return Bit.shift(value, -disposition)
end

return Bit
