local embed = require("../../src/embed/embed")
local stdPolyfills = require("../../luau_packages/std_polyfills")
local frktest = require("../../../../luau_packages/frktest")

local Embed = embed
local test = frktest.test
local check = frktest.assert.check

return function()
	test.case("Embed builds with basic fields", function()
		local e = Embed.new()
		e:setTitle("Hello"):setDescription("World"):setColor(0xFF0000)
		local json = e:build()

		check.equal(json.title, "Hello")
		check.equal(json.description, "World")
		check.equal(json.color, 0xFF0000)
	end)

	test.case("Embed builds without type field (type is optional)", function()
		local e = Embed.new()
		e:setTitle("No type")
		check.should_not_error(function()
			e:build()
			return
		end)
	end)

	test.case("Embed url set via constructor is applied", function()
		local e = Embed.new({ url = "https://example.com" })
		local json = e:build()

		check.equal(json.url, "https://example.com")
	end)

	test.case("Embed url set via setUrl is applied", function()
		local e = Embed.new()
		e:setUrl("https://example.com")
		local json = e:build()

		check.equal(json.url, "https://example.com")
	end)

	test.case("Embed timestamp is stored as ISO 8601 string", function()
		local e = Embed.new()
		local dt = stdPolyfills.datetime.fromUnixTimestamp(0)
		e:setTimestamp(dt)
		local json = e:build()

		check.equal(type(json.timestamp), "string")
	end)

	test.case("Embed errors when title exceeds 256 characters", function()
		local e = Embed.new()
		check.should_error(function()
			e:setTitle(string.rep("a", 257))
			return
		end)
	end)

	test.case("Embed errors when description exceeds 4096 characters", function()
		local e = Embed.new()
		check.should_error(function()
			e:setDescription(string.rep("a", 4097))
			return
		end)
	end)

	test.case("Embed errors when more than 25 fields are added", function()
		local e = Embed.new()
		for i = 1, 25 do
			e:addField({ name = tostring(i), value = "v", inline = false })
		end
		check.should_error(function()
			e:addField({ name = "26th", value = "v", inline = false })
			return
		end)
	end)

	test.case("Embed initializes correctly with resource table including url", function()
		local e = Embed.new({
			title = "My Title",
			description = "My Desc",
			url = "https://discord.com",
			color = 0x00FF00,
		})
		local json = e:build()

		check.equal(json.title, "My Title")
		check.equal(json.description, "My Desc")
		check.equal(json.url, "https://discord.com")
		check.equal(json.color, 0x00FF00)
	end)
end
