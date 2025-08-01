local intents = require("../src/intents")
local frktest = require("../../../lune_packages/frktest")

local Intents = intents
local test = frktest.test
local check = frktest.assert.check

-- Require dependencies for expected value calculation.
local apiTypes = require("../lune_packages/api_types")
local bit = require("../luau_packages/bit")

return function()
	test.case("Intents builder builds correct bitfield", function()
		local builder = Intents.new()
		builder:addIntent("GuildMembers")
		builder:addIntent("GuildMessages")
		local built = builder:build()

		local expected = bit.lshift(1, apiTypes.gateway.intents.GuildMembers)
			+ bit.lshift(1, apiTypes.gateway.intents.GuildMessages)
		check.equal(built, expected)
	end)

	test.case("Intents builder errors on duplicate intent", function()
		local builder = Intents.new()
		builder:addIntent("GuildMembers")
		check.should_error(function()
			builder:addIntent("GuildMembers")

			return
		end)
	end)

	test.case("Intents builder errors on invalid intent", function()
		local builder = Intents.new()
		check.should_error(function()
			builder:addIntent("InvalidIntent" :: any)

			return
		end)
	end)

	test.case("Intents builder allows chaining of methods", function()
		local builder = Intents.new()
		check.should_not_error(function()
			builder:addIntent("GuildMembers"):addIntent("GuildMessages")

			return builder
		end)
	end)
end
