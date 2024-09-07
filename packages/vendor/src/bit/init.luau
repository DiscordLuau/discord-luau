--[[
	A Bit wrapper library that supports both 64 Bit integers and 32 Bit integers. Primarily required in the calculation
	for snowflake IDs that the Discord API will give us.
]]

local MAXIMUM_32BIT_VALUE = 2147483647

local Bit64 = require("Bit64")
local Bit32 = bit32

local Bit = {}

function Bit.bnot(value: number)
	if value > MAXIMUM_32BIT_VALUE then
		return Bit64.bnot(value)
	else
		return Bit32.bnot(value)
	end
end

function Bit.bor(value0: number, value1: number)
	if value0 > MAXIMUM_32BIT_VALUE then
		return Bit64.bor(value0, value1)
	else
		return Bit32.bor(value0, value1)
	end
end

function Bit.band(value0: number, value1: number)
	if value0 > MAXIMUM_32BIT_VALUE then
		return Bit64.band(value0, value1)
	else
		return Bit32.band(value0, value1)
	end
end

function Bit.shift(value: number, disposition: number)
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

return Bit
