local frktest = require("../../../luau_packages/frktest")
local logger = require("../src")

local test = frktest.test
local check = frktest.assert.check

local function captureSink()
	local captured: { string } = {}

	local function sink(message: string)
		table.insert(captured, message)
	end

	local function getCaptured(): { string }
		return captured
	end

	return sink, getCaptured
end

return function()
	test.suite("construction", function()
		test.case("constructs without error", function()
			local instance = logger.new("Test")

			check.not_nil(instance)
		end)

		test.case("defaults to Debug log level", function()
			local instance = logger.new("Test")

			check.equal(instance:getLogLevel(), "Debug")
		end)

		test.case("accepts an explicit log level at construction", function()
			local instance = logger.new("Test", "Warn")

			check.equal(instance:getLogLevel(), "Warn")
		end)

		test.case("errors on an invalid log level string", function()
			check.should_error(function()
				logger.new("Test", "Invalid" :: any)

				return
			end)
		end)
	end)

	test.suite("setLogLevel / getLogLevel", function()
		test.case("round-trips through every valid level", function()
			local levels = { "Debug", "Info", "Notice", "Warn", "Error", "Critical", "Alert", "Emergency" }
			local instance = logger.new("Test")

			for _, level in levels do
				instance:setLogLevel(level :: any)

				check.equal(instance:getLogLevel(), level)
			end
		end)

		test.case("errors on an invalid level name", function()
			local instance = logger.new("Test")

			check.should_error(function()
				instance:setLogLevel("Nonsense" :: any)

				return
			end)
		end)
	end)

	test.suite("setSink", function()
		test.case("routes output to the provided callback instead of print", function()
			local instance = logger.new("Test")
			local sink, getCaptured = captureSink()

			instance:setSink(sink)
			instance:info("hello")

			check.equal(#getCaptured(), 1)
		end)

		test.case("captured line contains the log message text", function()
			local instance = logger.new("Test")
			local sink, getCaptured = captureSink()

			instance:setSink(sink)
			instance:info("my message")

			check.is_true(string.find(getCaptured()[1], "my message") ~= nil)
		end)

		test.case("captured line contains the logger name", function()
			local instance = logger.new("MyLogger")
			local sink, getCaptured = captureSink()

			instance:setSink(sink)
			instance:info("ping")

			check.is_true(string.find(getCaptured()[1], "MyLogger") ~= nil)
		end)

		test.case("each log call produces exactly one captured line", function()
			local instance = logger.new("Test")
			local sink, getCaptured = captureSink()

			instance:setSink(sink)
			instance:debug("a")
			instance:info("b")
			instance:notice("c")
			instance:warn("d")

			check.equal(#getCaptured(), 4)
		end)
	end)

	test.suite("level filtering", function()
		test.case("messages below the configured level are suppressed", function()
			local instance = logger.new("Test", "Warn")
			local sink, getCaptured = captureSink()

			instance:setSink(sink)
			instance:debug("suppressed")
			instance:info("suppressed")
			instance:notice("suppressed")

			check.equal(#getCaptured(), 0)
		end)

		test.case("messages at or above the configured level are emitted", function()
			local instance = logger.new("Test", "Warn")
			local sink, getCaptured = captureSink()

			instance:setSink(sink)
			instance:warn("emitted")
			instance:error("emitted")

			check.equal(#getCaptured(), 2)
		end)

		test.case("raising the log level suppresses previously visible messages", function()
			local instance = logger.new("Test", "Debug")
			local sink, getCaptured = captureSink()

			instance:setSink(sink)
			instance:debug("visible before raise")

			instance:setLogLevel("Warn")
			instance:debug("invisible after raise")

			check.equal(#getCaptured(), 1)
		end)

		test.case("lowering the log level reveals previously suppressed messages", function()
			local instance = logger.new("Test", "Warn")
			local sink, getCaptured = captureSink()

			instance:setSink(sink)
			instance:debug("suppressed before lower")

			instance:setLogLevel("Debug")
			instance:debug("visible after lower")

			check.equal(#getCaptured(), 1)
		end)
	end)

	test.suite("multiple instances are independent", function()
		test.case("each instance has its own sink", function()
			local instanceA = logger.new("A")
			local instanceB = logger.new("B")
			local sinkA, getCapturedA = captureSink()
			local sinkB, getCapturedB = captureSink()

			instanceA:setSink(sinkA)
			instanceB:setSink(sinkB)

			instanceA:info("from A")
			instanceB:info("from B")

			check.equal(#getCapturedA(), 1)
			check.equal(#getCapturedB(), 1)
		end)

		test.case("each instance has its own log level", function()
			local instanceA = logger.new("A", "Debug")
			local instanceB = logger.new("B", "Warn")
			local sinkA, getCapturedA = captureSink()
			local sinkB, getCapturedB = captureSink()

			instanceA:setSink(sinkA)
			instanceB:setSink(sinkB)

			instanceA:debug("visible")
			instanceB:debug("suppressed")

			check.equal(#getCapturedA(), 1)
			check.equal(#getCapturedB(), 0)
		end)
	end)
end
