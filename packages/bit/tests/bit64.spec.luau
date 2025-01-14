local frktest = require("../../../lune_packages/frktest")

local bit = require("../src")

local test = frktest.test
local check = frktest.assert.check

return function()
	-- -- https://circuitdigest.com/calculators/bit-shift-calculator
	test.case("is able to SHIFT a 64bit int", function()
		check.equal(bit.shift(685566749516628033, -2), 171391687379157020)
		check.equal(bit.shift(685566749516628033, 2), 2742266998066512400)
	end)

	-- -- https://dqydj.com/bitwise-not-calculator/#Bitwise_Not_Calculator
	test.case("is able to NOT a 64bit int", function()
		check.equal(bit.bnot(685566749516628033), 17761177324192924000)
	end)

	-- -- https://miniwebtool.com/bitwise-calculator/
	test.case("is able to OR a 64bit int", function()
		check.equal(bit.bor(685566749516628033, 0), 685566749516628033)
		check.equal(bit.bor(685566749516628033, 2), 685566749516628100)
	end)

	-- -- https://miniwebtool.com/bitwise-calculator/
	test.case("is able to AND a 64bit int", function()
		check.equal(bit.band(685566749516628033, 685566749516628033), 685566749516628033)
		check.equal(bit.band(685566749516628033, 4063232), 131072)
	end)
end
