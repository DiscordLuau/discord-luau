--[=[
	@class Types.guild
]=]

local util = require("../lune_packages/util")

local VerificationLevel = table.freeze(util.tableReflect({
	None = 0,
	Low = 1,
	Medium = 2,
	High = 3,
	VeryHigh = 4,
}))

local DefaultMessageNotification = table.freeze(util.tableReflect({
	AllMessages = 0,
	OnlyMentions = 1,
}))

local ExplicitContentFilterLevel = table.freeze(util.tableReflect({
	Disabled = 0,
	MembersWithoutRoles = 1,
	AllMembers = 2,
}))

local NSFWLevel = table.freeze(util.tableReflect({
	Default = 0,
	Explicit = 1,
	Safe = 2,
	AgeRestricted = 3,
}))

local PremiumTier = table.freeze(util.tableReflect({
	None = 0,
	Tier1 = 1,
	Tier2 = 2,
	Tier3 = 3,
}))

local MFALevel = table.freeze(util.tableReflect({
	None = 0,
	Elevated = 1,
}))

local InviteType = table.freeze(util.tableReflect({
	Guild = 0,
	GroupDM = 1,
	Friend = 2,
}))

local InviteTargetType = table.freeze(util.tableReflect({
	Stream = 1,
	EmbeddedApplication = 2,
}))

local ScheduledEventPrivacyLevel = table.freeze(util.tableReflect({
	GuildOnly = 2,
}))

local SchedledEventEntityType = table.freeze(util.tableReflect({
	StageInstance = 1,
	Voice = 2,
	External = 3,
}))

local SchedledEventStatus = table.freeze(util.tableReflect({
	Scheduled = 1,
	Active = 2,
	Completed = 3,
	Cancelled = 4,
}))

local IntegrationType = table.freeze(util.tableReflect({
	Twitch = "twitch",
	YouTube = "youtube",
	Discord = "discord",
	GuildSubscription = "guild_subscription",
}))

local IntegrationExpireBehaviour = table.freeze(util.tableReflect({
	RemoveRole = 0,
	Kick = 1,
}))

local OnboardingPromptType = table.freeze(util.tableReflect({
	MultipleChoice = "MULTIPLE_CHOICE",
	Dropdown = "DROPDOWN",
}))

local OnboardingMode = table.freeze(util.tableReflect({
	Default = "ONBOARDING_DEFAULT",
	Advanced = "ONBOARDING_ADVANCED",
}))

local OverwriteType = table.freeze(util.tableReflect({
	Role = 0,
	Member = 1,
}))

local TriggerTypes = table.freeze(util.tableReflect({
	Keyword = 1,
	Spam = 3,
	KeywordPreset = 4,
	MentionSpam = 5,
	MemberProfile = 6,
}))

local KeywordPresetType = table.freeze(util.tableReflect({
	Profanity = 1,
	SexualContent = 2,
	Slurs = 3,
}))

local EventTypes = table.freeze(util.tableReflect({
	MessageSend = 1,
	MemberUpdate = 2,
}))

local ActionTypes = table.freeze(util.tableReflect({
	BlockMessage = 1,
	SendAlertMessage = 2,
	Timeout = 3,
	BlockMemberInteraction = 4,
}))

local AuditLogEvent = table.freeze(util.tableReflect({
	GuildUpdate = 1,
	ChannelCreate = 10,
	ChannelUpdate = 11,
	ChannelDelete = 12,
	ChannelOverwriteCreate = 13,
	ChannelOverwriteUpdate = 14,
	ChannelOverwriteDelete = 15,
	MemberKick = 20,
	MemberPrune = 21,
	MemberBanAdd = 22,
	MemberBanRemove = 23,
	MemberUpdate = 24,
	MemberRoleUpdate = 25,
	MemberMove = 26,
	MemberDisconnect = 27,
	BotAdd = 28,
	RoleCreate = 30,
	RoleUpdate = 31,
	RoleDelete = 32,
	InviteCreate = 40,
	InviteUpdate = 41,
	InviteDelete = 42,
	WebhookCreate = 50,
	WebhookUpdate = 51,
	WebhookDelete = 52,
	EmojiCreate = 60,
	EmojiUpdate = 61,
	EmojiDelete = 62,
	MessageDelete = 72,
	MessageBulkDelete = 73,
	MessagePin = 74,
	MessageUnpin = 75,
	IntegrationCreate = 80,
	IntegrationUpdate = 81,
	IntegrationDelete = 82,
	StageInstanceCreate = 83,
	StageInstanceUpdate = 84,
	StageInstanceDelete = 85,
	StickerCreate = 90,
	StickerUpdate = 91,
	StickerDelete = 92,
	GuildScheduledEventCreate = 100,
	GuildScheduledEventUpdate = 101,
	GuildScheduledEventDelete = 102,
	ThreadCreate = 110,
	ThreadUpdate = 111,
	ThreadDelete = 112,
	ApplicationCommandPermissionUpdate = 121,
	SoundboardSoundCreate = 130,
	SoundboardSoundUpdate = 131,
	SoundboardSoundDelete = 132,
	AutoModerationRuleCreate = 140,
	AutoModerationRuleUpdate = 141,
	AutoModerationRuleDelete = 142,
	AutoModerationBlockMessage = 143,
	AutoModerationFlagToChannel = 144,
	AutoModerationUserCommunicationDisabled = 145,
	CreatorMonetizationRequestCreated = 150,
	CreatorMonetizationTermsAccepted = 151,
	OnboardingPromptCreate = 163,
	OnboardingPromptUpdate = 164,
	OnboardingPromptDelete = 165,
	OnboardingCreate = 166,
	OnboardingUpdate = 167,
	HomeSettingsCreate = 190,
	HomeSettingsUpdate = 191,
}))

export type ActionTypes = "BlockMessage" | "SendAlertMessage" | "Timeout" | "BlockMemberInteraction"
export type EventTypes = "MessageSend" | "MemberUpdate"
export type KeywordPresetType = "Profanity" | "SexualContent" | "Slurs"
export type TriggerTypes = "Keyword" | "Spam" | "KeywordPreset" | "MentionSpam" | "MemberProfile"
export type VerificationLevel = "None" | "Low" | "Medium" | "High" | "VeryHigh"
export type DefaultMessageNotification = "AllMessages" | "OnlyMentions"
export type ExplicitContentFilterLevel = "Disabled" | "MembersWithoutRoles" | "AllMembers"
export type NSFWLevel = "Default" | "Explicit" | "Safe" | "AgeRestricted"
export type PremiumTier = "None" | "Tier1" | "Tier2" | "Tier3"
export type MFALevel = "None" | "Elevated"
export type InviteType = "Guild" | "GroupDM" | "Friend"
export type InviteTargetType = "Stream" | "EmbeddedApplication"
export type ScheduledEventPrivacyLevel = "GuildOnly"
export type SchedledEventEntityType = "StageInstance" | "Voice" | "External"
export type SchedledEventStatus = "Scheduled" | "Active" | "Completed" | "Canceled"
export type IntegrationType = "Twitch" | "YouTube" | "Discord" | "GuildSubscription"
export type IntegrationExpireBehaviour = "RemoveRole" | "Kick"
export type OnboardingPromptType = "MultipleChoice" | "Dropdown"
export type OnboardingMode = "Default" | "Advanced"
export type OverwriteType = "Role" | "Member"
export type AuditLogEvent =
	"GuildUpdate"
	| "ChannelCreate"
	| "ChannelUpdate"
	| "ChannelDelete"
	| "MessageCreate"
	| "MessageUpdate"
	| "MessageDelete"
	| "ReactionAdd"
	| "ReactionRemove"
	| "PresenceUpdate"
	| "VoiceStateUpdate"
	| "TypingStart"

return {
	AuditLogEvent = AuditLogEvent,
	TriggerTypes = TriggerTypes,
	KeywordPresetType = KeywordPresetType,
	EventTypes = EventTypes,
	ActionTypes = ActionTypes,
	VerificationLevel = VerificationLevel,
	DefaultMessageNotification = DefaultMessageNotification,
	ExplicitContentFilterLevel = ExplicitContentFilterLevel,
	NSFWLevel = NSFWLevel,
	PremiumTier = PremiumTier,
	MFALevel = MFALevel,
	InviteType = InviteType,
	InviteTargetType = InviteTargetType,
	ScheduledEventPrivacyLevel = ScheduledEventPrivacyLevel,
	SchedledEventEntityType = SchedledEventEntityType,
	SchedledEventStatus = SchedledEventStatus,
	IntegrationType = IntegrationType,
	IntegrationExpireBehaviour = IntegrationExpireBehaviour,
	OnboardingPromptType = OnboardingPromptType,
	OnboardingMode = OnboardingMode,
	OverwriteType = OverwriteType,
}
