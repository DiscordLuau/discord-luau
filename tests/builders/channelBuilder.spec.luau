local frktest = require("@frktest/frktest")

local test = frktest.test
local check = frktest.assert.check

return function()
	test.case("example case", function()
		-- error(123)
	end)
end
