local testEntitlement = require("../../src/entitlement/testEntitlement")
local frktest = require("../../../../luau_packages/frktest")
local apiTypes = require("../../luau_packages/api_types")

local TestEntitlement = testEntitlement
local test = frktest.test
local check = frktest.assert.check

return function()
	test.case("TestEntitlement builds with required fields (Guild)", function()
		local te = TestEntitlement.new()
		te:setSkuId("sku-123"):setOwnerId("guild-456"):setOwnerType("Guild")
		local json = te:build()

		check.equal(json.sku_id, "sku-123")
		check.equal(json.owner_id, "guild-456")
		check.equal(json.owner_type, apiTypes.entitlement.EntitlementOwnerType.Guild)
		check.equal(type(json.owner_type), "number")
	end)

	test.case("TestEntitlement builds with required fields (User)", function()
		local te = TestEntitlement.new()
		te:setSkuId("sku-123"):setOwnerId("user-789"):setOwnerType("User")
		local json = te:build()

		check.equal(json.owner_type, apiTypes.entitlement.EntitlementOwnerType.User)
		check.equal(type(json.owner_type), "number")
	end)

	test.case("TestEntitlement owner_type Guild maps to 1", function()
		local te = TestEntitlement.new()
		te:setSkuId("s"):setOwnerId("o"):setOwnerType("Guild")
		local json = te:build()

		check.equal(json.owner_type, 1)
	end)

	test.case("TestEntitlement owner_type User maps to 2", function()
		local te = TestEntitlement.new()
		te:setSkuId("s"):setOwnerId("o"):setOwnerType("User")
		local json = te:build()

		check.equal(json.owner_type, 2)
	end)

	test.case("TestEntitlement build errors when sku_id is missing", function()
		local te = TestEntitlement.new()
		te:setOwnerId("o"):setOwnerType("Guild")
		check.should_error(function()
			te:build()
			return
		end)
	end)

	test.case("TestEntitlement build errors when owner_id is missing", function()
		local te = TestEntitlement.new()
		te:setSkuId("s"):setOwnerType("Guild")
		check.should_error(function()
			te:build()
			return
		end)
	end)

	test.case("TestEntitlement build errors when owner_type is missing", function()
		local te = TestEntitlement.new()
		te:setSkuId("s"):setOwnerId("o")
		check.should_error(function()
			te:build()
			return
		end)
	end)

	test.case("TestEntitlement rejects invalid owner_type", function()
		local te = TestEntitlement.new()
		check.should_error(function()
			te:setOwnerType("Invalid" :: any)
			return
		end)
	end)
end
