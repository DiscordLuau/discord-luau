-- NOTE: we're using the `Lune` runtime in the CI/CD environment, so we're not going to be using the `@std-polyfills`
-- package that the discord-luau package uses.

local task = require("@lune/task")

local frktest = require("@frktest/frktest")

local future = require("@vendor/future")

local test = frktest.test
local check = frktest.assert.check

return function()
	test.case("is able to construct an future object", function()
		local object = future.new(function() end)

		check.not_nil(object)
	end)

	test.case("is able to resolve future objects", function()
		local variable

		local object = future.new(function()
			task.wait()

			variable = "Hello World"
		end)

		object:await()

		check.equal(variable, "Hello World")
	end)
end
