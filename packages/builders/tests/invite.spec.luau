local invite = require("../src/invite")
local frktest = require("../../../lune_packages/frktest")
local apiTypes = require("../lune_packages/api_types")

local Invite = invite
local test = frktest.test
local check = frktest.assert.check

return function()
	test.case("Invite builder builds JSON with provided properties", function()
		local inv = Invite.new()
		inv:setMaxAge(3600)
			:setMaxUses(10)
			:setTemporary(true)
			:setIsUnique(false)
			:setTargetType("Stream")
			:setTargetUser("123456789012345678")
			:setTargetApplication("876543210987654321")
		local json = inv:build()

		check.equal(json.max_age, 3600)
		check.equal(json.max_uses, 10)
		check.equal(json.temporary, true)
		check.equal(json.unique, false)
		-- Validate that the mapping returns the expected value.
		check.equal(json.target_type, apiTypes.guild.InviteTargetType.Stream)
		check.equal(json.target_user_id, "123456789012345678")
		check.equal(json.target_application_id, "876543210987654321")
	end)

	test.case("Invite builder allows method chaining", function()
		local inv = Invite.new()
		check.should_not_error(function()
			inv:setMaxAge(1800):setMaxUses(5):setTemporary(false):setIsUnique(true)
			return inv
		end)
	end)

	test.case("Invite builder initializes correctly with resource table", function()
		local resource = {
			maxAge = 7200,
			maxUses = 20,
			temporary = true,
			unique = true,
			targetType = "Stream" :: "Stream", -- using a valid invite target type.
			targetUserId = "111111111111111111",
			targetApplicationId = "222222222222222222",
		}
		local inv = Invite.new(resource)
		local json = inv:build()

		check.equal(json.max_age, 7200)
		check.equal(json.max_uses, 20)
		check.equal(json.temporary, true)
		check.equal(json.unique, true)
		check.equal(json.target_type, apiTypes.guild.InviteTargetType.Stream)
		check.equal(json.target_user_id, "111111111111111111")
		check.equal(json.target_application_id, "222222222222222222")
	end)

	test.case("Invite builder errors for invalid max age", function()
		local inv = Invite.new()
		check.should_error(function()
			inv:setMaxAge(-1)

			return
		end)
		check.should_error(function()
			inv:setMaxAge(604801)

			return
		end)
	end)

	test.case("Invite builder errors for invalid max uses", function()
		local inv = Invite.new()
		check.should_error(function()
			inv:setMaxUses(-1)

			return
		end)
		check.should_error(function()
			inv:setMaxUses(101)

			return
		end)
	end)

	test.case("Invite builder errors for invalid target type", function()
		local inv = Invite.new()
		check.should_error(function()
			inv:setTargetType("INVALID_TYPE" :: any)

			return
		end)
	end)
end
