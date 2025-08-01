local builders = require("../src")
local frktest = require("../../../lune_packages/frktest")

local builder = builders.channel

local test = frktest.test
local check = frktest.assert.check

return function()
	test.case("ChannelBuilder creates a channel with correct properties", function()
		local builder = builder.new()

		local channel =
			builder:setName("test-channel"):setType("GuildText"):setTopic("Test topic"):setPosition(1):build()

		check.equal(channel.name, "test-channel")
		check.equal(channel.type, 0)
		check.equal(channel.topic, "Test topic")
		check.equal(channel.position, 1)
	end)

	test.case("ChannelBuilder allows chaining of methods", function()
		local builder = builder.new()

		check.should_not_error(function()
			builder:setName("chained-channel"):setType("GuildText"):setTopic("Chained topic"):setPosition(2)

			return builder
		end)
	end)
end
