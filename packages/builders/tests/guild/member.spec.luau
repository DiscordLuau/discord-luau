local member = require("../../src/guild/member")
local frktest = require("../../../../luau_packages/frktest")

local GuildMember = member
local test = frktest.test
local check = frktest.assert.check

return function()
	test.case("GuildMember build returns all nil when nothing is set", function()
		local m = GuildMember.new()
		local json = m:build()

		check.equal(json.nick, nil)
		check.equal(json.roles, nil)
		check.equal(json.mute, nil)
		check.equal(json.deaf, nil)
		check.equal(json.channel_id, nil)
		check.equal(json.communication_disabled_until, nil)
		check.equal(json.flags, nil)
	end)

	test.case("GuildMember setNick passes through", function()
		local m = GuildMember.new()
		m:setNick("cool nickname")
		local json = m:build()

		check.equal(json.nick, "cool nickname")
	end)

	test.case("GuildMember setNick nil clears nick", function()
		local m = GuildMember.new()
		m:setNick(nil)
		local json = m:build()

		check.equal(json.nick, nil)
	end)

	test.case("GuildMember setRoles passes through", function()
		local m = GuildMember.new()
		m:setRoles({ "111", "222", "333" })
		local json = m:build()

		check.equal(json.roles ~= nil, true)
		local roles = json.roles
		assert(roles, "roles should not be nil")
		check.equal(roles[1], "111")
		check.equal(roles[3], "333")
	end)

	test.case("GuildMember setMute=false is emitted", function()
		local m = GuildMember.new()
		m:setMute(false)
		local json = m:build()

		check.equal(json.mute, false)
	end)

	test.case("GuildMember setDeaf=true is emitted", function()
		local m = GuildMember.new()
		m:setDeaf(true)
		local json = m:build()

		check.equal(json.deaf, true)
	end)

	test.case("GuildMember setChannelId nil disconnects from voice", function()
		local m = GuildMember.new()
		m:setChannelId(nil)
		local json = m:build()

		check.equal(json.channel_id, nil)
	end)

	test.case("GuildMember setCommunicationDisabledUntil passes through", function()
		local m = GuildMember.new()
		m:setCommunicationDisabledUntil("2026-06-01T00:00:00Z")
		local json = m:build()

		check.equal(json.communication_disabled_until, "2026-06-01T00:00:00Z")
	end)
end
