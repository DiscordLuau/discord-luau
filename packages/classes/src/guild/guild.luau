--[[
	Implementation of the Discord Guild class in Luau

	https://discord.com/developers/docs/resources/guild#guild-object
]]

local _future = require("@vendor/future")

local _request = require("@rest/request")

local _guild = require("@rest/guild")

local apiTypes = require("@api-types/apiTypes")

local state = require("@classes/state")
local emoji = require("@classes/emoji")
local sticker = require("@classes/sticker")
local role = require("@classes/guild/role")
local welcomeScreen = require("@classes/guild/welcomeScreen")

local systemChannelBitflag = require("@classes/bitflags/systemChannel")

local Guild = {}

Guild.Interface = {}
Guild.Prototype = {}

function Guild.Prototype.sync(self: Guild, guildData: apiTypes.GuildObject)
	local emojiArray = {}
	local rolesArray = {}
	local stickerArray = {}

	for _, emojiData in guildData.emojis do
		table.insert(emojiArray, emoji.new(emojiData))
	end

	for _, roleData in guildData.roles do
		table.insert(rolesArray, role.new(roleData))
	end

	for _, stickerData in next, guildData.stickers or {} do
		table.insert(stickerArray, sticker.new(stickerData))
	end

	if guildData.welcome_screen then
		self.welcomeScreen = welcomeScreen.new(guildData.welcome_screen)
	end

	self.stickers = stickerArray
	self.roles = rolesArray
	self.emojis = emojiArray

	self.verificationLevel = (
		guildData.verification_level == 0 and "None"
		or guildData.verification_level == 1 and "Low"
		or guildData.verification_level == 2 and "Medium"
		or guildData.verification_level == 3 and "High"
		or guildData.verification_level == 4 and "VeryHigh"
	) :: GuildVerificationLevel
	self.defaultMessageNotifications = (
		guildData.default_message_notifications == 0 and "AllMessages"
		or guildData.default_message_notifications == 1 and "OnlyMmentions"
	) :: GuildDefaultMessageNotificationLevel
	self.explicitContentFilter = (
		guildData.explicit_content_filter == 0 and "Disabled"
		or guildData.explicit_content_filter == 1 and "MembersWithoutRoles"
		or guildData.explicit_content_filter == 2 and "AllMembers"
	) :: GuildExplicitContentFilterLevel
	self.premiumTier = (
		guildData.premium_tier == 0 and "None"
		or guildData.premium_tier == 1 and "Tier1"
		or guildData.premium_tier == 2 and "Tier2"
		or guildData.premium_tier == 3 and "Tier3"
	) :: GuildPremiumTier
	self.nsfwLevel = (
		guildData.nsfw_level == 0 and "Default"
		or guildData.nsfw_level == 1 and "Explicit"
		or guildData.nsfw_level == 2 and "Safe"
		or guildData.nsfw_level == 3 and "AgeRestricted"
	) :: GuildNSFWLevel
	self.mfaLevel = (guildData.mfa_level == 0 and "None" or guildData.mfa_level == 1 and "Elevated") :: GuildMFALevel

	self.systemChannelFlags = guildData.system_channel_flags
		and systemChannelBitflag.new(guildData.system_channel_flags)

	self.icon = guildData.icon
	self.iconHash = guildData.icon_hash
	self.name = guildData.name
	self.splash = guildData.splash
	self.discoverySplash = guildData.discovery_splash
	self.owner = guildData.owner
	self.ownerId = guildData.owner_id
	self.permissions = guildData.permissions
	self.region = guildData.region
	self.afkChannelId = guildData.afk_channel_id
	self.afkTimeout = guildData.afk_timeout
	self.widgetEnabled = guildData.widget_enabled
	self.widgetChannelId = guildData.widget_channel_id
	self.features = guildData.features
	self.applicationId = guildData.application_id
	self.systemChannelId = guildData.system_channel_id
	self.rulesChannelId = guildData.rules_channel_id
	self.maxPresences = guildData.max_presences
	self.maxMembers = guildData.max_members
	self.vanityUrlCode = guildData.vanity_url_code
	self.description = guildData.description
	self.banner = guildData.banner
	self.premiumSubscriptionCount = guildData.premium_subscription_count
	self.preferredLocale = guildData.preferred_locale
	self.publicUpdatesChannelId = guildData.public_updates_channel_id
	self.maxVideoChannelUsers = guildData.max_video_channel_users
	self.maxStageVideoChannelUsers = guildData.max_stage_video_channel_users
	self.approximateMemberCount = guildData.approximate_member_count
	self.approximatePresenceCount = guildData.approximate_presence_count
	self.premiumProgressBarEnabled = guildData.premium_progress_bar_enabled
	self.safetyAlertsChannelId = guildData.safety_alerts_channel_id
end

function Guild.Interface.new(state: state.State, guildData: apiTypes.GuildObject): Guild
	local self = setmetatable(
		{
			state = state,

			id = guildData.id,
			isUnavailable = false,
		} :: Guild,
		{ __index = Guild.Prototype }
	)

	self:sync(guildData)

	return self
end

export type GuildNSFWLevel = "Default" | "Explicit" | "Safe" | "AgeRestricted"
export type GuildPremiumTier = "None" | "Tier1" | "Tier2" | "Tier3"
export type GuildMFALevel = "None" | "Elevated"
export type GuildExplicitContentFilterLevel = "Disabled" | "MembersWithoutRoles" | "AllMembers"
export type GuildDefaultMessageNotificationLevel = "AllMessages" | "OnlyMmentions"
export type GuildVerificationLevel = "None" | "Low" | "Medium" | "High" | "VeryHigh"

export type Guild = typeof(Guild.Prototype) & {
	state: state.State,

	id: apiTypes.Snowflake,
	isUnavailable: boolean,

	stickers: { sticker.Sticker },
	emojis: { emoji.Emoji },
	roles: { role.Role },
	welcomeScreen: welcomeScreen.WelcomeScreen?,

	icon: string,
	iconHash: string?,
	name: string,
	splash: string,
	discoverySplash: string,
	owner: boolean,
	ownerId: apiTypes.Snowflake,
	permissions: string,
	region: string,
	afkChannelId: apiTypes.Snowflake?,
	afkTimeout: number,
	widgetEnabled: boolean,
	widgetChannelId: apiTypes.Snowflake?,
	verificationLevel: GuildVerificationLevel,
	defaultMessageNotifications: GuildDefaultMessageNotificationLevel,
	explicitContentFilter: GuildExplicitContentFilterLevel,
	features: { apiTypes.GuildFeature },
	mfaLevel: GuildMFALevel,
	applicationId: apiTypes.Snowflake,
	systemChannelId: apiTypes.Snowflake?,
	systemChannelFlags: systemChannelBitflag.SystemChannelBitflag?,
	rulesChannelId: apiTypes.Snowflake?,
	maxPresences: number?,
	maxMembers: number?,
	vanityUrlCode: string?,
	description: string?,
	banner: string?,
	premiumTier: GuildPremiumTier,
	premiumSubscriptionCount: number?,
	preferredLocale: string,
	publicUpdatesChannelId: apiTypes.Snowflake?,
	maxVideoChannelUsers: number?,
	maxStageVideoChannelUsers: number?,
	approximateMemberCount: number?,
	approximatePresenceCount: number?,
	nsfwLevel: GuildNSFWLevel,
	premiumProgressBarEnabled: boolean,
	safetyAlertsChannelId: apiTypes.Snowflake?,
}

return Guild.Interface
