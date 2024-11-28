local frktest = require("../../../lune_packages/frktest")

local bit = require("../src")

local BIT64_NUMBER = 2147483647 + 1
local DISCORD_ID = 685566749516628033

local test = frktest.test
local check = frktest.assert.check

return function()
	-- https://circuitdigest.com/calculators/bit-shift-calculator
	test.case("is able to SHIFT a 64bit int", function()
		check.equal(bit.shift(BIT64_NUMBER, -2), 8589934592)
		check.equal(bit.shift(BIT64_NUMBER, 2), 536870912)
	end)

	-- https://dqydj.com/bitwise-not-calculator/#Bitwise_Not_Calculator
	test.case("is able to NOT a 64bit int", function()
		check.equal(bit.bnot(BIT64_NUMBER), 18446744071562068000)
	end)

	-- https://miniwebtool.com/bitwise-calculator/
	test.case("is able to OR a 64bit int", function()
		check.equal(bit.bor(BIT64_NUMBER, 0), BIT64_NUMBER)
		check.equal(bit.bor(BIT64_NUMBER, 2), 2147483650)
	end)

	-- https://miniwebtool.com/bitwise-calculator/
	test.case("is able to AND a 64bit int", function()
		check.equal(bit.band(BIT64_NUMBER, BIT64_NUMBER), BIT64_NUMBER)
		check.equal(bit.band(DISCORD_ID, 0x3E0000), 131072)
	end)
end
