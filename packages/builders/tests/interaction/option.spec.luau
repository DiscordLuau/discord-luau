local option = require("../../src/interaction/option")
local frktest = require("../../../../luau_packages/frktest")
local apiTypes = require("../../luau_packages/api_types")

local Option = option
local test = frktest.test
local check = frktest.assert.check

return function()
	test.case("Option builds a String option with required fields", function()
		local o = Option.new()
		o:setType("String"):setName("my-option"):setDescription("An option")
		local json = o:build()

		check.equal(json.name, "my-option")
		check.equal(json.description, "An option")
		check.equal(json.type, apiTypes.interaction.ApplicationCommandOptionType.String)
	end)

	test.case("Option setName rejects uppercase letters", function()
		local o = Option.new()
		o:setType("String")
		check.should_error(function()
			o:setName("MyOption")
			return
		end)
	end)

	test.case("Option setName allows hyphens and underscores", function()
		local o = Option.new()
		o:setType("String")
		check.should_not_error(function()
			o:setName("my_option-name")
			return
		end)
	end)

	test.case("Option build errors when name is missing", function()
		local o = Option.new()
		o:setType("String"):setDescription("desc")
		check.should_error(function()
			o:build()
			return
		end)
	end)

	test.case("Option build error message for missing name is not self-referential", function()
		local o = Option.new()
		o:setType("String"):setDescription("desc")
		local ok, err = pcall(function()
			o:build()
		end)
		check.equal(ok, false)
		check.equal(err ~= nil, true)
		check.equal(string.find(tostring(err), "nil") == nil, true)
	end)

	test.case("Option channel_types are emitted as integers", function()
		local o = Option.new()
		o:setType("Channel"):setName("my-channel"):setDescription("a channel")
		o:addChannelType("GuildText")
		local json = o:build()

		check.equal(json.channel_types ~= nil, true)
		local channel_types = json.channel_types
		assert(channel_types, "channel_types should not be nil")
		check.equal(channel_types[1], apiTypes.channel.ChannelTypes.GuildText)
		check.equal(type(channel_types[1]), "number")
	end)

	test.case("Option required cannot be set on SubCommand", function()
		local o = Option.new()
		o:setType("SubCommand")
		check.should_error(function()
			o:setRequired(true)
			return
		end)
	end)

	test.case("Option min/max length validation for String type", function()
		local o = Option.new()
		o:setType("String")
		check.should_error(function()
			o:setMinLength(-1)
			return
		end)
		check.should_error(function()
			o:setMaxLength(6001)
			return
		end)
	end)
end
