local reflect = require("@utils/table/reflect")

local VerificationLevel = table.freeze(reflect({
	None = 0,
	Low = 1,
	Medium = 2,
	High = 3,
	VeryHigh = 4,
}))

local DefaultMessageNotification = table.freeze(reflect({
	AllMessages = 0,
	OnlyMentions = 1,
}))

local ExplicitContentFilterLevel = table.freeze(reflect({
	Disabled = 0,
	MembersWithoutRoles = 1,
	AllMembers = 2,
}))

local NSFWLevel = table.freeze(reflect({
	Default = 0,
	Explicit = 1,
	Safe = 2,
	AgeRestricted = 3,
}))

local PremiumTier = table.freeze(reflect({
	None = 0,
	Tier1 = 1,
	Tier2 = 2,
	Tier3 = 3,
}))

local MFALevel = table.freeze(reflect({
	None = 0,
	Elevated = 1,
}))

export type VerificationLevel = "None" | "Low" | "Medium" | "High" | "VeryHigh"
export type DefaultMessageNotification = "AllMessages" | "OnlyMentions"
export type ExplicitContentFilterLevel = "Disabled" | "MembersWithoutRoles" | "AllMembers"
export type NSFWLevel = "Default" | "Explicit" | "Safe" | "AgeRestricted"
export type PremiumTier = "None" | "Tier1" | "Tier2" | "Tier3"
export type MFALevel = "None" | "Elevated"

return {
	VerificationLevel = VerificationLevel,
	DefaultMessageNotification = DefaultMessageNotification,
	ExplicitContentFilterLevel = ExplicitContentFilterLevel,
	NSFWLevel = NSFWLevel,
	PremiumTier = PremiumTier,
	MFALevel = MFALevel,
}
