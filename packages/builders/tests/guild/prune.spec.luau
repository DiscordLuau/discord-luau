local prune = require("../../src/guild/prune")
local frktest = require("../../../../luau_packages/frktest")

local GuildPrune = prune
local test = frktest.test
local check = frktest.assert.check

return function()
	test.case("GuildPrune builds with no fields set", function()
		local p = GuildPrune.new()
		local json = p:build()

		check.equal(json.days, nil)
		check.equal(json.compute_prune_count, nil)
		check.equal(json.include_roles, nil)
	end)

	test.case("GuildPrune days is passed through", function()
		local p = GuildPrune.new()
		p:setDays(7)
		local json = p:build()

		check.equal(json.days, 7)
	end)

	test.case("GuildPrune days accepts 1", function()
		local p = GuildPrune.new()
		check.should_not_error(function()
			p:setDays(1)
			return
		end)
	end)

	test.case("GuildPrune days accepts 30", function()
		local p = GuildPrune.new()
		check.should_not_error(function()
			p:setDays(30)
			return
		end)
	end)

	test.case("GuildPrune days rejects 0", function()
		local p = GuildPrune.new()
		check.should_error(function()
			p:setDays(0)
			return
		end)
	end)

	test.case("GuildPrune days rejects 31", function()
		local p = GuildPrune.new()
		check.should_error(function()
			p:setDays(31)
			return
		end)
	end)

	test.case("GuildPrune compute_prune_count=false is emitted", function()
		local p = GuildPrune.new()
		p:setComputePruneCount(false)
		local json = p:build()

		check.equal(json.compute_prune_count, false)
	end)

	test.case("GuildPrune include_roles is passed through", function()
		local p = GuildPrune.new()
		p:setIncludeRoles({ "111", "222" })
		local json = p:build()

		local include_roles = json.include_roles
		assert(include_roles, "include_roles should not be nil")
		check.equal(include_roles[1], "111")
		check.equal(include_roles[2], "222")
	end)
end
