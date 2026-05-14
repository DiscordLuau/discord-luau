local frktest = require("../../../luau_packages/frktest")
local secret = require("../src")

local test = frktest.test
local check = frktest.assert.check

return function()
	test.case("value is readable after construction", function()
		local s = secret.new("my-token")
		check.equal(s.value, "my-token")
	end)

	test.case("value is readable for non-string types", function()
		local s = secret.new(42)
		check.equal(s.value, 42)
	end)

	test.case("tostring masks the latter half of a string secret", function()
		local s = secret.new("ABCDEFGH")
		check.equal(tostring(s), "Secret(ABCD----)")
	end)

	test.case("tostring masks odd-length strings by flooring the visible portion", function()
		local s = secret.new("ABCDE")
		check.equal(tostring(s), "Secret(AB---)")
	end)

	test.case("tostring shows the type name for non-string secrets", function()
		check.equal(tostring(secret.new(99)), "Secret(number)")
		check.equal(tostring(secret.new({})), "Secret(table)")
		check.equal(tostring(secret.new(true)), "Secret(boolean)")
	end)

	test.case("# returns the length of a string secret", function()
		check.equal(#secret.new("hello"), 5)
	end)

	test.case("# returns the sequence length of a table secret", function()
		check.equal(#secret.new({ 10, 20, 30 }), 3)
	end)

	test.case("# errors on a non-string non-table secret", function()
		local s = secret.new(42)
		check.should_error(function()
			local _ = #s
			return
		end)
	end)

	test.case("concat works with Secret on the left", function()
		local s = secret.new("world")
		check.equal((s :: any) .. "!", "world!")
	end)

	test.case("concat works with Secret on the right", function()
		local s = secret.new("world")
		check.equal("hello " .. (s :: any), "hello world")
	end)

	test.case("concat errors when the Secret wraps a non-string", function()
		local s = secret.new(42)
		check.should_error(function()
			local _ = (s :: any) .. "suffix"
			return
		end)
		check.should_error(function()
			local _ = "prefix" .. (s :: any)
			return
		end)
	end)

	test.case("value equality with a matching plain value returns true", function()
		local s = secret.new("token")
		check.equal(s.value == "token", true)
	end)

	test.case("value equality with a non-matching plain value returns false", function()
		local s = secret.new("token")
		check.equal(s.value == "wrong", false)
	end)

	test.case("equality between two Secrets with the same value returns true", function()
		local a = secret.new("shared")
		local b = secret.new("shared")
		check.equal(a == b, true)
	end)

	test.case("equality between two Secrets with different values returns false", function()
		local a = secret.new("foo")
		local b = secret.new("bar")
		check.equal(a == b, false)
	end)

	test.case("writing to value errors", function()
		local s = secret.new("original")
		check.should_error(function()
			local obj = s :: any
			obj.value = "replaced"
			return
		end)
	end)

	test.case("value remains unchanged after a failed write attempt", function()
		local s = secret.new("original")
		pcall(function()
			local obj = s :: any
			obj.value = "replaced"
		end)
		check.equal(s.value, "original")
	end)

	test.case("writing any new field errors", function()
		local s = secret.new("original")
		check.should_error(function()
			local obj = s :: any
			obj.extra = true
			return
		end)
	end)

	test.case("getmetatable returns the lock string not the real metatable", function()
		local s = secret.new("token")
		check.equal(getmetatable(s :: any), "The metatable is locked.")
	end)
end
