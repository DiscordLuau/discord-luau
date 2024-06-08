local Enumerate = require("@Utils/Enumerate")
local Construct = require("@Utils/Construct")

local Resolvable = require("@Network/Resolvable")

local PermissionsBuilder = require("@Builders/PermissionsBuilder")
local GuildRoleBuilder = require("@Builders/GuildRoleBuilder")
local ChannelBuilder = require("@Builders/ChannelBuilder")

local ResolvableType = require("@Enums/ResolveableType")

--[=[
	@class Builders.GuildBuilder
]=]
local GuildBuilder = {}

GuildBuilder.Interface = {}
GuildBuilder.Prototype = {}

GuildBuilder.Prototype.type = "GuildBuilder"

--[=[
	@prop VerificationLevel table
	@within Builders.GuildBuilder

	An enumeration of filter levels.

	- None: 0
	- Low: 1
	- Medium: 2
	- High: 2
	- VeryHigh: 2
]=]
GuildBuilder.Interface.VerificationLevel = Enumerate.new({
	None = 0,
	Low = 1,
	Medium = 2,
	High = 3,
	VeryHigh = 4,
})

--[=[
	@prop NotificationLevel table
	@within Builders.GuildBuilder

	An enumeration of filter levels.

	- AllMessages: 0
	- OnlyMentions: 1
]=]
GuildBuilder.Interface.NotificationLevel = Enumerate.new({
	AllMessages = 0,
	OnlyMentions = 1,
})

--[=[
	@prop ExplicitContentFilterLevel table
	@within Builders.GuildBuilder

	An enumeration of filter levels.

	- Disabled: 0
	- MembersWithoutRoles: 1
	- AllMembers: 2
]=]
GuildBuilder.Interface.ExplicitContentFilterLevel = Enumerate.new({
	Disabled = 0,
	MembersWithoutRoles = 1,
	AllMembers = 2,
})

--[=[
	@prop GuildFeature table
	@within Builders.GuildBuilder

	An enumeration of guild features.

	- AnimatedBanner: "ANIMATED_BANNER"
	- AnimatedIcon: "ANIMATED_ICON"
	- ApplicationCommandPermissionsV2: "APPLICATION_COMMAND_PERMISSIONS_V2"
	- AutoModeration: "AUTO_MODERATION"
	- Banner: "BANNER"
	- Community: "COMMUNITY"
	- CreatorMonetizableProvisional: "CREATOR_MONETIZABLE_PROVISIONAL"
	- CreatorStorePage: "CREATOR_STORE_PAGE"
	- DeveloperSupportServer: "DEVELOPER_SUPPORT_SERVER"
	- Discoverable: "DISCOVERABLE"
	- Featurable: "FEATURABLE"
	- InvitesDisabled: "INVITES_DISABLED"
	- InviteSplash: "INVITE_SPLASH"
	- MemberVerificationGateEnabled: "MEMBER_VERIFICATION_GATE_ENABLED"
	- MoreStickers: "MORE_STICKERS"
	- News: "NEWS"
	- Partnered: "PARTNERED"
	- PreviewEnabled: "PREVIEW_ENABLED"
	- RaidAlertsDisabled: "RAID_ALERTS_DISABLED"
	- RoleIcons: "ROLE_ICONS"
	- RoleSubscriptionsAvaliableForPurchase: "ROLE_SUBSCRIPTIONS_AVAILABLE_FOR_PURCHASE"
	- RoleSubscriptionsEnabled: "ROLE_SUBSCRIPTIONS_ENABLED"
	- TicketedEventsEnabled: "TICKETED_EVENTS_ENABLED"
	- VanityUrl: "VANITY_URL"
	- Verified: "VERIFIED"
	- VipRegions: "VIP_REGIONS"
	- WelcomeScreenEnabled: "WELCOME_SCREEN_ENABLED"
]=]
GuildBuilder.Interface.GuildFeature = Enumerate.new({
	AnimatedBanner = "ANIMATED_BANNER",
	AnimatedIcon = "ANIMATED_ICON",
	ApplicationCommandPermissionsV2 = "APPLICATION_COMMAND_PERMISSIONS_V2",
	AutoModeration = "AUTO_MODERATION",
	Banner = "BANNER",
	Community = "COMMUNITY",
	CreatorMonetizableProvisional = "CREATOR_MONETIZABLE_PROVISIONAL",
	CreatorStorePage = "CREATOR_STORE_PAGE",
	DeveloperSupportServer = "DEVELOPER_SUPPORT_SERVER",
	Discoverable = "DISCOVERABLE",
	Featurable = "FEATURABLE",
	InvitesDisabled = "INVITES_DISABLED",
	InviteSplash = "INVITE_SPLASH",
	MemberVerificationGateEnabled = "MEMBER_VERIFICATION_GATE_ENABLED",
	MoreStickers = "MORE_STICKERS",
	News = "NEWS",
	Partnered = "PARTNERED",
	PreviewEnabled = "PREVIEW_ENABLED",
	RaidAlertsDisabled = "RAID_ALERTS_DISABLED",
	RoleIcons = "ROLE_ICONS",
	RoleSubscriptionsAvaliableForPurchase = "ROLE_SUBSCRIPTIONS_AVAILABLE_FOR_PURCHASE",
	RoleSubscriptionsEnabled = "ROLE_SUBSCRIPTIONS_ENABLED",
	TicketedEventsEnabled = "TICKETED_EVENTS_ENABLED",
	VanityUrl = "VANITY_URL",
	Verified = "VERIFIED",
	VipRegions = "VIP_REGIONS",
	WelcomeScreenEnabled = "WELCOME_SCREEN_ENABLED",
})

--[=[
	Sets the name of this discord guild.
	
	@method setName
	@param name string
	@within Builders.GuildBuilder
	@return Objects.GuildBuilder
]=]
function GuildBuilder.Prototype.setName(self: GuildBuilder, name: string)
	self.name = name

	return self
end

--[=[
	Sets the verification level for this guild.
	
	@method setVerificationLevel
	@param verificationLevel number
	@within Builders.GuildBuilder
	@return Objects.GuildBuilder
]=]
function GuildBuilder.Prototype.setVerificationLevel(self: GuildBuilder, verificationLevel: number)
	GuildBuilder.Interface.VerificationLevel:Assert(verificationLevel)

	self.verificationLevel = verificationLevel

	return self
end

--[=[
	Sets the default message notification level for this guild.
	
	@method setDefaultMessageNotificationLevel
	@param notificationLevel number
	@within Builders.GuildBuilder
	@return Objects.GuildBuilder
]=]
function GuildBuilder.Prototype.setDefaultMessageNotificationLevel(self: GuildBuilder, notificationLevel: number)
	GuildBuilder.Interface.NotificationLevel:Assert(notificationLevel)

	self.defaultMessageNotifications = notificationLevel

	return self
end

--[=[
	Sets the explicit content filter level for this guild.
	
	@method setExplicitContentFilterLevel
	@param notificationLevel number
	@within Builders.GuildBuilder
	@return Objects.GuildBuilder
]=]
function GuildBuilder.Prototype.setExplicitContentFilterLevel(self: GuildBuilder, contentFilterLevel: number)
	GuildBuilder.Interface.ExplicitContentFilterLevel:Assert(contentFilterLevel)

	self.explicitContentFilter = contentFilterLevel

	return self
end

--[=[
	Sets the discord Afk Voice Channel for this guild.
	
	@method setAfkChannelId
	@param channelId string
	@within Builders.GuildBuilder
	@return Objects.GuildBuilder
]=]
function GuildBuilder.Prototype.setAfkChannelId(self: GuildBuilder, channelId: string)
	self.afkChannelId = channelId

	return self
end

--[=[
	Sets the timeout for members in discord voice channels. Valid inputs are:

	- 60
	- 300
	- 900
	- 1800
	- 3600
	
	@method setAfkTimeout
	@param timeout number
	@within Builders.GuildBuilder
	@return Objects.GuildBuilder
]=]
function GuildBuilder.Prototype.setAfkTimeout(self: GuildBuilder, timeout: number)
	self.afkTimeout = timeout

	return self
end

--[=[
	Sets the icon of this guild. imageData must be a base64, 1024x1024, encoded binary data for either a png/jpeg/gif
	
	@method setIcon
	@param imageData string
	@within Builders.GuildBuilder
	@return Objects.GuildBuilder
]=]
function GuildBuilder.Prototype.setIcon(self: GuildBuilder, imageData: string)
	self.icon = imageData

	return self
end

--[=[
	Sets the owner of this guild.
	
	@method setOwnerId
	@param ownerId string
	@within Builders.GuildBuilder
	@return Objects.GuildBuilder
]=]
function GuildBuilder.Prototype.setOwnerId(self: GuildBuilder, ownerId: string)
	self.ownerId = ownerId

	return self
end

--[=[
	Sets the splash for this guild. imageData must be a 16:9, base64, encoded binary data for either a png/jpeg
	
	@method setSplash
	@param imageData string
	@within Builders.GuildBuilder
	@return Objects.GuildBuilder
]=]
function GuildBuilder.Prototype.setSplash(self: GuildBuilder, imageData: string)
	self.splash = imageData

	return self
end

--[=[
	Sets the discovery splash for this guild. imageData must be a 16:9, base64, encoded binary data for either a png/jpeg
	
	@method setDiscoverySplash
	@param imageData string
	@within Builders.GuildBuilder
	@return Objects.GuildBuilder
]=]
function GuildBuilder.Prototype.setDiscoverySplash(self: GuildBuilder, imageData: string)
	self.discoverySplash = imageData

	return self
end

--[=[
	Sets the banner for this guild. imageData must be a 16:9, base64, encoded binary data for either a png/jpeg
	
	@method setSysetBannerstemChannelId
	@param imageData string
	@within Builders.GuildBuilder
	@return Objects.GuildBuilder
]=]
function GuildBuilder.Prototype.setBanner(self: GuildBuilder, imageData: string)
	self.banner = imageData

	return self
end

--[=[
	Sets the System Channel for this guild.
	
	@method setSystemChannelId
	@param channelId string
	@within Builders.GuildBuilder
	@return Objects.GuildBuilder
]=]
function GuildBuilder.Prototype.setSystemChannelId(self: GuildBuilder, channelId: string)
	self.systemChannelId = channelId

	return self
end

--[=[
	Sets the flags for the System Channel in this guild.
	
	@method setSystemChannelFlags
	@param flags number
	@within Builders.GuildBuilder
	@return Objects.GuildBuilder
]=]
function GuildBuilder.Prototype.setSystemChannelFlags(self: GuildBuilder, flags: number)
	self.systemChannelFlags = flags

	return self
end

--[=[
	Sets the rules channel for this guild.
	
	@method setRulesChannelId
	@param channelId string
	@within Builders.GuildBuilder
	@return Objects.GuildBuilder
]=]
function GuildBuilder.Prototype.setRulesChannelId(self: GuildBuilder, channelId: string)
	self.rulesChannelId = channelId

	return self
end

--[=[
	Sets the public update channel for this guild
	
	@method setPublicUpdateChannelId
	@param channelId string
	@within Builders.GuildBuilder
	@return Objects.GuildBuilder
]=]
function GuildBuilder.Prototype.setPublicUpdateChannelId(self: GuildBuilder, channelId: string)
	self.publicUpdateChannelId = channelId

	return self
end

--[=[
	Sets the preferred locale of this guild
	
	@method setPreferredLocale
	@param locale string
	@within Builders.GuildBuilder
	@return Objects.GuildBuilder
]=]
function GuildBuilder.Prototype.setPreferredLocale(self: GuildBuilder, locale: string)
	self.preferredLocale = locale

	return self
end

--[=[
	Enables developers to specify features that are apart of this guild.
	
	@method addFeature
	@param feature string
	@within Builders.GuildBuilder
	@return Objects.GuildBuilder
]=]
function GuildBuilder.Prototype.addFeature(self: GuildBuilder, featureName: string)
	GuildBuilder.Interface.GuildFeature:Assert(featureName)

	table.insert(self.features, featureName)

	return self
end

--[=[
	Sets the description of this guild
	
	@method setDescription
	@param description string
	@within Builders.GuildBuilder
	@return Objects.GuildBuilder
]=]
function GuildBuilder.Prototype.setDescription(self: GuildBuilder, description: string)
	self.description = description

	return self
end

--[=[
	Sets if the Premium Progress bar is enabled
	
	@method setPremiumProgressBarEnabled
	@param enabled boolean
	@within Builders.GuildBuilder
	@return Objects.GuildBuilder
]=]
function GuildBuilder.Prototype.setPremiumProgressBarEnabled(self: GuildBuilder, enabled: boolean)
	self.premiumProgressBarEnabled = enabled

	return self
end

--[=[
	Sets the Safety Alert channel id
	
	@method setSafetyAlertsChannelId
	@param channelId string
	@within Builders.GuildBuilder
	@return Objects.GuildBuilder
]=]
function GuildBuilder.Prototype.setSafetyAlertsChannelId(self: GuildBuilder, channelId: string)
	self.safetyAlertsChannelId = channelId

	return self
end

--[=[
	Enables developers to add a Role to a discord Guild channel upon creation.
	
	@method addRole
	@param role Objects.GuildRoleBuilder
	@within Builders.GuildBuilder
	@return Objects.GuildBuilder
]=]
function GuildBuilder.Prototype.addRole(self: GuildBuilder, role: GuildRoleBuilder.GuildRoleBuilder)
	table.insert(self.roles, role)

	return self
end

--[=[
	Enables developers to add a Channel to a discord Guild channel upon creation.
	
	@method addChannel
	@param channel Objects.ChannelBuilder
	@within Builders.GuildBuilder
	@return Objects.GuildBuilder
]=]
function GuildBuilder.Prototype.addChannel(self: GuildBuilder, channel: ChannelBuilder.ChannelBuilder)
	table.insert(self.channels, channel)

	return self
end

--[=[
	Converts the guild to a JSON object that can be sent to the Discord API.
	
	@method toPayloadObject
	@within Builders.GuildBuilder
	@return Network.Resolvable
]=]
function GuildBuilder.Prototype.toPayloadObject(self: GuildBuilder)
	local roleObjects = {}
	local channelObjects = {}

	for _, role in self.roles do
		table.insert(roleObjects, role:toPayloadObject():resolve())
	end

	for _, channel in self.channels do
		table.insert(channelObjects, channel:toPayloadObject():resolve())
	end

	return Resolvable.new(ResolvableType.JSON, {
		name = self.name,
		description = self.description,
		verification_level = self.verificationLevel,
		default_message_notifications = self.defaultMessageNotifications,
		explicit_content_filter = self.explicitContentFilter,
		afk_channel_id = self.afkChannelId,
		afk_timeout = self.afkTimeout,
		icon = self.icon,
		owner_id = self.ownerId,
		splash = self.splash,
		discovery_splash = self.discoverySplash,
		banner = self.banner,
		system_channel_id = self.systemChannelId,
		system_channel_flags = self.systemChannelFlags,
		rules_channel_id = self.rulesChannelId,
		public_updates_channel_id = self.publicUpdateChannelId,
		preferred_locale = self.preferredLocale,
		features = self.features,
		premium_progress_bar_enabled = self.premiumProgressBarEnabled,
		safety_alerts_channel_id = self.safetyAlertsChannelId,
		roles = #roleObjects > 0 and roleObjects or nil,
		channels = #channelObjects > 0 and channelObjects or nil,
	})
end

--[=[
	Creates a new instance of GuildBuilder.
	
	@function new
	@within Builders.GuildBuilder
	@return Builders.GuildBuilder -- A new instance of GuildBuilder.
]=]
function GuildBuilder.Interface.new()
	return (
		Construct({
			features = {},
			roles = {},
			channels = {},
		}, GuildBuilder.Prototype) :: unknown
	) :: GuildBuilder
end

export type GuildBuilder = typeof(GuildBuilder.Prototype) & {
	name: string,
	description: string,
	verificationLevel: number,
	defaultMessageNotifications: number,
	explicitContentFilter: number,
	afkChannelId: string,
	afkTimeout: number,
	icon: string,
	ownerId: string,
	splash: string,
	discoverySplash: string,
	banner: string,
	systemChannelId: string,
	systemChannelFlags: number,
	rulesChannelId: string,
	publicUpdateChannelId: string,
	preferredLocale: string,
	features: { string },
	premiumProgressBarEnabled: boolean,
	safetyAlertsChannelId: string,
	roles: { GuildRoleBuilder.GuildRoleBuilder },
	channels: { ChannelBuilder.ChannelBuilder },
}

return GuildBuilder.Interface
