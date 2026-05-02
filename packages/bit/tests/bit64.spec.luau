local frktest = require("../../../luau_packages/frktest")

local bit = require("../src")

local test = frktest.test
local check = frktest.assert.check

return function()
	-- https://circuitdigest.com/calculators/bit-shift-calculator
	test.case("is able to SHIFT a 64bit int", function()
		check.equal(bit.shift(685566749516628033, -2), 171391687379157020)
		check.equal(bit.shift(685566749516628033, 2), 2742266998066512400)
	end)

	-- https://dqydj.com/bitwise-not-calculator/#Bitwise_Not_Calculator
	test.case("is able to NOT a 64bit int", function()
		check.equal(bit.bnot(685566749516628033), 17761177324192924000)
	end)

	-- https://miniwebtool.com/bitwise-calculator/
	test.case("is able to OR a 64bit int", function()
		check.equal(bit.bor(685566749516628033, 0), 685566749516628033)
		check.equal(bit.bor(685566749516628033, 2), 685566749516628100)
	end)

	-- https://miniwebtool.com/bitwise-calculator/
	test.case("is able to AND a 64bit int", function()
		check.equal(bit.band(685566749516628033, 685566749516628033), 685566749516628033)
		check.equal(bit.band(685566749516628033, 4063232), 131072)
	end)

	test.case("lshift produces correct values for displacements >= 32", function()
		-- 1 << 32 = 4294967296
		check.equal(bit.lshift(1, 32), 4294967296)
		-- 1 << 43 = 8796093022208  (CreateGuildExpressions)
		check.equal(bit.lshift(1, 43), 8796093022208)
		-- 1 << 44 = 17592186044416  (CreateEvents)
		check.equal(bit.lshift(1, 44), 17592186044416)
		-- 1 << 51 = 2251799813685248  (PinMessages)
		check.equal(bit.lshift(1, 51), 2251799813685248)
		-- 1 << 52 = 4503599627370496  (BypassSlowmode)
		check.equal(bit.lshift(1, 52), 4503599627370496)
	end)

	test.case("band works correctly with values above 0xFFFFFFFF", function()
		-- 0xFFFFFFFF00000000 & 0x0000FFFF00000000 = 0x0000FFFF00000000 = 281470681743360
		check.equal(bit.band(0xFFFFFFFF00000000, 0x0000FFFF00000000), 281470681743360)

		local pinMessages = bit.lshift(1, 51)
		check.equal(bit.band(pinMessages, pinMessages), pinMessages)

		local bypassSlowmode = bit.lshift(1, 52)
		check.equal(bit.band(pinMessages, bypassSlowmode), 0)
	end)

	test.case("bor accumulates high permission flags correctly", function()
		local pinMessages = bit.lshift(1, 51)
		local bypassSlowmode = bit.lshift(1, 52)
		local combined = bit.bor(pinMessages, bypassSlowmode)

		check.equal(bit.band(combined, pinMessages), pinMessages)
		check.equal(bit.band(combined, bypassSlowmode), bypassSlowmode)
	end)

	test.case("bnot and band correctly clears a high permission flag", function()
		local pinMessages = bit.lshift(1, 51)
		local bypassSlowmode = bit.lshift(1, 52)
		local combined = bit.bor(pinMessages, bypassSlowmode)

		local result = bit.band(combined, bit.bnot(pinMessages))
		check.equal(bit.band(result, pinMessages), 0)
		check.equal(bit.band(result, bypassSlowmode), bypassSlowmode)
	end)
end
