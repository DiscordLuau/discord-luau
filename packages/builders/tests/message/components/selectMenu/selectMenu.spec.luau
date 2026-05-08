local selectMenu = require("../../../../src/message/components/selectMenu/selectMenu")
local frktest = require("../../../../../../luau_packages/frktest")
local apiTypes = require("../../../../luau_packages/api_types")

local SelectMenu = selectMenu
local test = frktest.test
local check = frktest.assert.check

return function()
	test.case("SelectMenu builds with type and customId", function()
		local sm = SelectMenu.new()
		sm:setType("String"):setCustomId("my-menu")
		local json = sm:build()

		check.equal(json.custom_id, "my-menu")
		check.equal(json.type, apiTypes.channel.SelectMenuType.String)
	end)

	test.case("SelectMenu channel_types are emitted as integers not strings", function()
		local sm = SelectMenu.new()
		sm:setType("Channel"):setCustomId("channel-menu")
		sm:addChannelType("GuildText")
		sm:addChannelType("GuildVoice")
		local json = sm:build()

		check.equal(json.channel_types ~= nil, true)
		local channel_types = json.channel_types
		assert(channel_types)
		check.equal(channel_types[1], apiTypes.channel.ChannelTypes.GuildText)
		check.equal(channel_types[2], apiTypes.channel.ChannelTypes.GuildVoice)
		check.equal(type(channel_types[1]), "number")
		check.equal(type(channel_types[2]), "number")
	end)

	test.case("SelectMenu channel_types is nil when none added", function()
		local sm = SelectMenu.new()
		sm:setType("String"):setCustomId("my-menu")
		local json = sm:build()

		check.equal(json.channel_types, nil)
	end)

	test.case("SelectMenu build errors when type is not set", function()
		local sm = SelectMenu.new()
		sm:setCustomId("my-menu")
		check.should_error(function()
			sm:build()
			return
		end)
	end)

	test.case("SelectMenu build errors when customId is not set", function()
		local sm = SelectMenu.new()
		sm:setType("String")
		check.should_error(function()
			sm:build()
			return
		end)
	end)

	test.case("SelectMenu build errors when maxValues < minValues", function()
		local sm = SelectMenu.new()
		sm:setType("String"):setCustomId("my-menu")
		sm:setMinValues(5):setMaxValues(3)
		check.should_error(function()
			sm:build()
			return
		end)
	end)

	test.case("SelectMenu placeholder is passed through", function()
		local sm = SelectMenu.new()
		sm:setType("String"):setCustomId("my-menu"):setPlaceholder("Choose one")
		local json = sm:build()

		check.equal(json.placeholder, "Choose one")
	end)
end
