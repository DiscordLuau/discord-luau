--[=[
	@class Builders.TestEntitlement
	@__index Prototype

	Implementation of Discord's Create Test Entitlement params as a Luau builder.

	https://discord.com/developers/docs/monetization/entitlements#create-test-entitlement-json-params
]=]

local apiTypes = require("../../luau_packages/api_types")

local TestEntitlement = {}

TestEntitlement.Prototype = {}
TestEntitlement.Interface = {}

function TestEntitlement.Prototype.setSkuId(self: TestEntitlement, skuId: string): TestEntitlement
	self.skuId = skuId
	return self
end

function TestEntitlement.Prototype.setOwnerId(self: TestEntitlement, ownerId: string): TestEntitlement
	self.ownerId = ownerId
	return self
end

function TestEntitlement.Prototype.setOwnerType(
	self: TestEntitlement,
	ownerType: apiTypes.EntitlementOwnerType
): TestEntitlement
	assert(apiTypes.entitlement.EntitlementOwnerType[ownerType], "Invalid owner type")
	self.ownerType = ownerType
	return self
end

function TestEntitlement.Prototype.build(self: TestEntitlement): JSON
	assert(self.skuId, "TestEntitlement is missing a sku_id")
	assert(self.ownerId, "TestEntitlement is missing an owner_id")
	assert(self.ownerType, "TestEntitlement is missing an owner_type")

	return {
		sku_id = self.skuId,
		owner_id = self.ownerId,
		owner_type = apiTypes.entitlement.EntitlementOwnerType[self.ownerType],
	}
end

function TestEntitlement.Interface.new(resource: {
	skuId: string?,
	ownerId: string?,
	ownerType: apiTypes.EntitlementOwnerType?,
}?): TestEntitlement
	local self = setmetatable({} :: TestEntitlement, { __index = TestEntitlement.Prototype })

	if resource then
		if resource.skuId then
			self:setSkuId(resource.skuId)
		end
		if resource.ownerId then
			self:setOwnerId(resource.ownerId)
		end
		if resource.ownerType then
			self:setOwnerType(resource.ownerType)
		end
	end

	return self
end

export type TestEntitlement = typeof(TestEntitlement.Prototype) & {
	skuId: string?,
	ownerId: string?,
	ownerType: apiTypes.EntitlementOwnerType?,
}

export type JSON = typeof(TestEntitlement.Prototype.build(nil :: any))

return TestEntitlement.Interface
