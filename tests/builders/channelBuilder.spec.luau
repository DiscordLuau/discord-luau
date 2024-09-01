local builder = require("@builders/channel")
local frktest = require("@frktest/frktest")

local test = frktest.test
local check = frktest.assert.check

return function()
	test.case("ChannelBuilder creates a channel with correct properties", function()
		local builder = builder.new()

		local channel =
			builder:setName("test-channel"):setType("GuildText"):setTopic("Test topic"):setPosition(1):build()

		check.equal(channel.name, "test-channel")
		check.equal(channel.type, "GuildText")
		check.equal(channel.topic, "Test topic")
		check.equal(channel.position, 1)
	end)

	test.case("ChannelBuilder throws error when required properties are missing", function()
		local builder = builder.new()

		check.should_error(function()
			builder:build()

			return
		end)
	end)

	test.case("ChannelBuilder allows chaining of methods", function()
		local builder = builder.new()

		check.should_not_error(function()
			builder:setName("chained-channel"):setType("GuildVoice"):setTopic("Chained topic"):setPosition(2)

			return builder
		end)
	end)
end
