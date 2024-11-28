--[[
	An 64-bit library to provide 64-bit binary operation in luau, ideally luau would expose some sort of bit64 lib,
	but they don't, so this is the un-optimised, awkward approach!
]]
local Bit64 = {}

--[[
	Converts a number to a binary string.
]]
local function toBinary(number: number): string
	local binary = select(
		1,
		string.gsub(string.format("%o", number), ".", function(x)
			return ({
				"000",
				"001",
				"010",
				"011",
				"100",
				"101",
				"110",
				"111",
			})[tonumber(x) :: number + 1]
		end)
	)

	binary = `{string.rep("0", math.max(64 - #binary, 0))}{binary}`

	return binary
end

--[[
	Converts a binary string to a number.
]]
local function toNumber(binary: string): number
	return tonumber(binary, 2) :: number
end

--[[
	Binary NOT operation for 64 bit ints
]]
function Bit64.bnot(value: number)
	local binary = toBinary(value)

	binary = string.gsub(binary, ".", function(x)
		if x == "0" then
			return "1"
		else
			return "0"
		end
	end)

	return toNumber(binary)
end

--[[
	Binary OR operation for 64 bit ints
]]
function Bit64.bor(value0: number, value1: number)
	local binary0 = toBinary(value0)
	local binary1 = toBinary(value1)

	local outputBinary = ``

	for index = 1, #binary0 do
		local binary0Bit = tonumber(string.sub(binary0, index, index)) :: number
		local binary1Bit = tonumber(string.sub(binary1, index, index)) :: number

		if binary0Bit + binary1Bit > 0 then
			outputBinary ..= "1"
		else
			outputBinary ..= "0"
		end
	end

	return toNumber(outputBinary)
end

--[[
	Binary AND operation for 64 bit ints
]]
function Bit64.band(value0: number, value1: number)
	local binary0 = toBinary(value0)
	local binary1 = toBinary(value1)

	local outputBinary = ``

	for index = 1, #binary0 do
		local binary0Bit = tonumber(string.sub(binary0, index, index)) :: number
		local binary1Bit = tonumber(string.sub(binary1, index, index)) :: number

		outputBinary ..= tostring(binary0Bit * binary1Bit)
	end

	return toNumber(outputBinary)
end

--[[
	Binary SHIFT operation for 64 bit ints, disposition is the number of bits to shift by, can support negative values
]]
function Bit64.shift(value: number, disposition: number)
	local binary = toBinary(value)

	if disposition > 0 then
		binary = string.sub(binary, 0, #binary - disposition)
		binary = `{string.rep("0", disposition)}{binary}`
	else
		disposition = math.abs(disposition)

		binary = string.sub(binary, -(#binary - disposition))
		binary = `{binary}{string.rep("0", disposition)}`
	end

	return toNumber(binary)
end

return Bit64
