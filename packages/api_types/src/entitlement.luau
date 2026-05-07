--[=[
	@class Types.entitlement
]=]

local util = require("../luau_packages/util")

local EntitlementType = table.freeze(util.tableReflect({
	Purchase = 1,
	PremiumSubscription = 2,
	DeveloperGift = 3,
	TestModePurchase = 4,
	FreePurchase = 5,
	UserGift = 6,
	PremiumPurchase = 7,
	ApplicationSubscription = 8,
}))

local EntitlementOwnerType = table.freeze(util.tableReflect({
	Guild = 1,
	User = 2,
}))

export type EntitlementType =
	"Purchase"
	| "PremiumSubscription"
	| "DeveloperGift"
	| "TestModePurchase"
	| "FreePurchase"
	| "UserGift"
	| "PremiumPurchase"
	| "ApplicationSubscription"

export type EntitlementOwnerType = "Guild" | "User"

return {
	EntitlementType = EntitlementType,
	EntitlementOwnerType = EntitlementOwnerType,
}
