local ban = require("../../src/guild/ban")
local frktest = require("../../../../luau_packages/frktest")

local GuildBan = ban
local test = frktest.test
local check = frktest.assert.check

return function()
	test.case("GuildBan builds with no fields set", function()
		local b = GuildBan.new()
		local json = b:build()

		check.equal(json.delete_message_seconds, nil)
	end)

	test.case("GuildBan delete_message_seconds is passed through", function()
		local b = GuildBan.new()
		b:setDeleteMessageSeconds(86400)
		local json = b:build()

		check.equal(json.delete_message_seconds, 86400)
	end)

	test.case("GuildBan delete_message_seconds accepts 0", function()
		local b = GuildBan.new()
		check.should_not_error(function()
			b:setDeleteMessageSeconds(0)
			return
		end)
	end)

	test.case("GuildBan delete_message_seconds accepts max 604800", function()
		local b = GuildBan.new()
		check.should_not_error(function()
			b:setDeleteMessageSeconds(604800)
			return
		end)
	end)

	test.case("GuildBan delete_message_seconds rejects values above 604800", function()
		local b = GuildBan.new()
		check.should_error(function()
			b:setDeleteMessageSeconds(604801)
			return
		end)
	end)

	test.case("GuildBan delete_message_seconds rejects negative values", function()
		local b = GuildBan.new()
		check.should_error(function()
			b:setDeleteMessageSeconds(-1)
			return
		end)
	end)
end
