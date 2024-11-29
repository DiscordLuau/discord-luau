local utilities = require("../lune_packages/utilities")

local EntitlementType = table.freeze(utilities.table.reflect({
	Purchase = 1,
	PremiumSubscription = 2,
	DeveloperGift = 3,
	TestModePurchase = 4,
	FreePurchase = 5,
	UserGift = 6,
	PremiumPurchase = 7,
	ApplicationSubscription = 8,
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

return {
	EntitlementType = EntitlementType,
}
