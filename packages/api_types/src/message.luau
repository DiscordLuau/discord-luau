--[=[
	@class Types.message
]=]

local util = require("../lune_packages/util")

local MessageType = table.freeze(util.tableReflect({
	Default = 0,
	RecipientAdd = 1,
	RecipientRemove = 2,
	Call = 3,
	ChannelNameChange = 4,
	ChannelIconChange = 5,
	ChannelPinnedMessage = 6,
	UserJoin = 7,
	GuildBoost = 8,
	GuildBoostTier1 = 9,
	GuildBoostTier2 = 10,
	GuildBoostTier3 = 11,
	ChannelFollowAdd = 12,
	GuildDiscoveryDisqualified = 14,
	GuildDiscoveryRequalified = 15,
	GuildDiscoveryGracePeriodInitialWarning = 16,
	GuildDiscoveryGracePeriodFinalWarning = 17,
	ThreadCreated = 18,
	Reply = 19,
	ChatInputCommand = 20,
	ThreadStarterMessage = 21,
	GuildInviteReminder = 22,
	ContextMenuCommand = 23,
	AutoModerationAction = 24,
	RoleSubscriptionPurchase = 25,
	InteractionPremiumUpsell = 26,
	StageStart = 27,
	StageEnd = 28,
	StageSpeaker = 29,
	StageTopic = 31,
	GuildApplicationPremiumSubscription = 32,
	GuildIncidentAlertModeEnabled = 36,
	GuildIncidentAlertModeDisabled = 37,
	GuildIncidentReportRaid = 38,
	GuildIncidentReportFalseAlarm = 39,
	PurchaseNotification = 44,
	PollResult = 46,
}))

local MessageAcitvityType = table.freeze(util.tableReflect({
	Join = 1,
	Spectate = 2,
	Listen = 3,
	JoinRequest = 5,
}))

local MessageReferenceType = table.freeze(util.tableReflect({
	Default = 0,
	Forward = 1,
}))

local ButtonStyle = table.freeze(util.tableReflect({
	Blurple = 1,
	Grey = 2,
	Green = 3,
	Red = 4,
}))

local TextInputStyle = table.freeze(util.tableReflect({
	Short = 1,
	Paragraph = 2,
}))

local SelectDefaultValueType = table.freeze(util.tableReflect({
	Role = "role",
	User = "user",
	Channel = "channel",
}))

local PollLayoutType = table.freeze(util.tableReflect({
	Default = 1,
}))

local ReactionType = table.freeze(util.tableReflect({
	Normal = 0,
	Burst = 1,
}))

export type MessageType =
	"Default"
	| "RecipientAdd"
	| "RecipientRemove"
	| "Call"
	| "ChannelNameChange"
	| "ChannelIconChange"
	| "ChannelPinnedMessage"
	| "UserJoin"
	| "GuildBoost"
	| "GuildBoostTier1"
	| "GuildBoostTier2"
	| "GuildBoostTier3"
	| "ChannelFollowAdd"
	| "GuildDiscoveryDisqualified"
	| "GuildDiscoveryRequalified"
	| "GuildDiscoveryGracePeriodInitialWarning"
	| "GuildDiscoveryGracePeriodFinalWarning"
	| "ThreadCreated"
	| "Reply"
	| "ChatInputCommand"
	| "ThreadStarterMessage"
	| "GuildInviteReminder"
	| "ContextMenuCommand"
	| "AutoModerationAction"
	| "RoleSubscriptionPurchase"
	| "InteractionPremiumUpsell"
	| "StageStart"
	| "StageEnd"
	| "StageSpeaker"
	| "StageTopic"
	| "GuildApplicationPremiumSubscription"
	| "GuildIncidentAlertModeEnabled"
	| "GuildIncidentAlertModeDisabled"
	| "GuildIncidentReportRaid"
	| "GuildIncidentReportFalseAlarm"
	| "PurchaseNotification"
	| "PollResult"

export type MessageAcitvityType = "Join" | "Spectate" | "Listen" | "JoinRequest"
export type MessageReferenceType = "Default" | "Forward"

export type ButtonStyle = "Blurple" | "Grey" | "Green" | "Red" | "Grey"

export type SelectDefaultValueType = "User" | "Role" | "Channel"

export type TextInputStyle = "Short" | "Paragraph"

export type PollLayoutType = "Default"

export type ReactionType = "Normal" | "Burst"

return {
	MessageType = MessageType,
	MessageAcitvityType = MessageAcitvityType,
	MessageReferenceType = MessageReferenceType,
	ButtonStyle = ButtonStyle,
	TextInputStyle = TextInputStyle,
	SelectDefaultValueType = SelectDefaultValueType,
	PollLayoutType = PollLayoutType,
	ReactionType = ReactionType,
}
