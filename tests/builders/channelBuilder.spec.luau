local frktest = require("@frktest/frktest")

return function()
	frktest.test.case("example case", function()
		error(123)
	end)
end
