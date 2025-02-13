--[[
	Implementation of discords Permission Guild object as a Luau builder.	

	See permissions for more information about the allow and deny fields.

	https://discord.com/developers/docs/resources/guild
]]

local apiTypes = require("../../lune_packages/api_types")

local Guild = {}

Guild.Prototype = {}
Guild.Interface = {}

--[[
	set the name for this guild
]]
function Guild.Prototype.setName(self: Guild, name: string): Guild
	assert(#name <= 100, "Name must be less than 100 characters")
	assert(#name > 1, "Name must be greater than 1 characters")

	self.name = name

	return self
end

--[[
	set the explicit verification level for this guild
]]
function Guild.Prototype.setVerificationLevel(self: Guild, verificationLevel: apiTypes.VerificationLevel): Guild
	assert(apiTypes.guild.VerificationLevel[verificationLevel], "Invalid verification level")

	self.verificationLevel = verificationLevel

	return self
end

--[[
	set the explicit default message notifications for this guild
]]
function Guild.Prototype.setDefaultMessageNotifications(
	self: Guild,
	defaultMessageNotifications: apiTypes.DefaultMessageNotification
): Guild
	assert(
		apiTypes.guild.DefaultMessageNotification[defaultMessageNotifications],
		"Invalid defaultMessageNotifications level"
	)

	self.defaultMessageNotifications = defaultMessageNotifications

	return self
end

--[[
	set the explicit content filter level for this guild
]]
function Guild.Prototype.setExplicitContentFilter(
	self: Guild,
	explicitContentFilter: apiTypes.ExplicitContentFilterLevel
): Guild
	assert(apiTypes.guild.ExplicitContentFilterLevel[explicitContentFilter], "Invalid explicitContentFilter level")

	self.explicitContentFilter = explicitContentFilter

	return self
end

--[[
	set the id for afk channel
]]
function Guild.Prototype.setAfkChannelId(self: Guild, afkChannelId: apiTypes.Snowflake): Guild
	self.afkChannelId = afkChannelId

	return self
end

--[[
	afk timeout in seconds, can be set to: 60, 300, 900, 1800, 3600
]]
function Guild.Prototype.setAfkTimeout(self: Guild, afkTimeout: number): Guild
	self.afkTimeout = afkTimeout

	return self
end

--[[
	base64 1024x1024 png/jpeg/gif image for the guild icon (can be animated gif when the server has
	the ANIMATED_ICON feature)
]]
function Guild.Prototype.setIcon(self: Guild, source: string): Guild
	self.icon = source

	return self
end

--[[
	user id to transfer guild ownership to (must be owner)
]]
function Guild.Prototype.setOwnerId(self: Guild, ownerId: apiTypes.Snowflake): Guild
	self.ownerId = ownerId

	return self
end

--[[
	base64 16:9 png/jpeg image for the guild splash (when the server has the INVITE_SPLASH feature)
]]
function Guild.Prototype.setSplash(self: Guild, source: string): Guild
	self.splash = source

	return self
end

--[[
	base64 16:9 png/jpeg image for the guild discovery splash (when the server has the DISCOVERABLE feature)
]]
function Guild.Prototype.setDiscoverySplash(self: Guild, source: string): Guild
	self.discoverySplash = source

	return self
end

--[[
	base64 16:9 png/jpeg image for the guild banner (when the server has the BANNER feature; can be animated
	gif when the server has the ANIMATED_BANNER feature)
]]
function Guild.Prototype.setBanner(self: Guild, source: string): Guild
	self.banner = source

	return self
end

--[[
	the id of the channel where guild notices such as welcome messages and boost events are posted
]]
function Guild.Prototype.setSystemChannelId(self: Guild, systemChannelId: apiTypes.Snowflake): Guild
	self.systemChannelId = systemChannelId

	return self
end

--[[
	set the system channel flags
]]
function Guild.Prototype.setSystemChannelFlags(self: Guild, systemChannelFlags: number): Guild
	self.systemChannelFlags = systemChannelFlags

	return self
end

--[[
	the id of the channel where Community guilds display rules and/or guidelines
]]
function Guild.Prototype.setRulesChannelId(self: Guild, rulesChannelId: apiTypes.Snowflake): Guild
	self.rulesChannelId = rulesChannelId

	return self
end

--[[
	the id of the channel where admins and moderators of Community guilds receive notices from Discord
]]
function Guild.Prototype.setPublicUpdatesChannelId(self: Guild, publicUpdatesChannelId: apiTypes.Snowflake): Guild
	self.publicUpdatesChannelId = publicUpdatesChannelId

	return self
end

--[[
	the preferred locale of a Community guild used in server discovery and notices from Discord; defaults to "en-US"
]]
function Guild.Prototype.setPreferredLocale(self: Guild, preferredLocale: apiTypes.LanguageLocales): Guild
	self.preferredLocale = preferredLocale

	return self
end

--[[
	enable a specific guild feature for this guild
]]
function Guild.Prototype.addFeature(self: Guild, feature: apiTypes.GuildFeature): Guild
	table.insert(self.features, feature)

	return self
end

--[[
	the description for the guild
]]
function Guild.Prototype.setDescription(self: Guild, description: string): Guild
	self.description = description

	return self
end

--[[
	whether the guild's boost progress bar should be enabled
]]
function Guild.Prototype.setPremiumProgressBarEnabled(self: Guild, premiumProgressBarEnabled: boolean): Guild
	self.premiumProgressBarEnabled = premiumProgressBarEnabled

	return self
end

--[[
	the id of the channel where admins and moderators of Community guilds receive safety alerts from Discord
]]
function Guild.Prototype.setSafetyAlertsChannelId(self: Guild, safetyAlertsChannelId: apiTypes.Snowflake): Guild
	self.safetyAlertsChannelId = safetyAlertsChannelId

	return self
end

--[[
	Responsible for building the Guild JSON that can be parsed by the Discord API.
]]
function Guild.Prototype.build(self: Guild): JSON
	return {
		name = self.name,
		verification_level = apiTypes.guild.VerificationLevel[self.verificationLevel],
		default_message_notifications = apiTypes.guild.DefaultMessageNotification[self.defaultMessageNotifications],
		explicit_content_filter = apiTypes.guild.ExplicitContentFilterLevel[self.explicitContentFilter],
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
		public_updates_channel_id = self.publicUpdatesChannelId,
		preferred_locale = self.preferredLocale,
		features = #self.features ~= 0 and self.features or nil,
		description = self.description,
		premium_progress_bar_enabled = self.premiumProgressBarEnabled,
		safety_alerts_channel_id = self.safetyAlertsChannelId,
	}
end

--[[
	Responsible for creating a new Guild.

	```lua
	
	```
]]
function Guild.Interface.new(resource: {
	name: string?,
	verificationLevel: apiTypes.VerificationLevel?,
	defaultMessageNotifications: apiTypes.DefaultMessageNotification?,
	explicitContentFilter: apiTypes.ExplicitContentFilterLevel?,
	afkChannelId: apiTypes.Snowflake?,
	afkTimeout: number?,
	icon: string?,
	ownerId: apiTypes.Snowflake?,
	splash: string?,
	discoverySplash: string?,
	banner: string?,
	systemChannelId: apiTypes.Snowflake?,
	systemChannelFlags: number?,
	rulesChannelId: apiTypes.Snowflake?,
	publicUpdatesChannelId: apiTypes.Snowflake?,
	preferredLocale: apiTypes.LanguageLocales?,
	features: { apiTypes.GuildFeature }?,
	description: string?,
	premiumProgressBarEnabled: boolean?,
	safetyAlertsChannelId: apiTypes.Snowflake?,
}?): Guild
	local self = setmetatable(
		{
			features = {},
		} :: Guild,
		{
			__index = Guild.Prototype,
		}
	)

	if resource then
		if resource.name then
			self:setName(resource.name)
		end

		if resource.verificationLevel then
			self:setVerificationLevel(resource.verificationLevel)
		end

		if resource.defaultMessageNotifications then
			self:setDefaultMessageNotifications(resource.defaultMessageNotifications)
		end

		if resource.explicitContentFilter then
			self:setExplicitContentFilter(resource.explicitContentFilter)
		end

		if resource.afkChannelId then
			self:setAfkChannelId(resource.afkChannelId)
		end

		if resource.afkTimeout then
			self:setAfkTimeout(resource.afkTimeout)
		end

		if resource.icon then
			self:setIcon(resource.icon)
		end

		if resource.ownerId then
			self:setOwnerId(resource.ownerId)
		end

		if resource.splash then
			self:setSplash(resource.splash)
		end

		if resource.discoverySplash then
			self:setDiscoverySplash(resource.discoverySplash)
		end

		if resource.banner then
			self:setBanner(resource.banner)
		end

		if resource.systemChannelId then
			self:setSystemChannelId(resource.systemChannelId)
		end

		if resource.systemChannelFlags then
			self:setSystemChannelFlags(resource.systemChannelFlags)
		end

		if resource.rulesChannelId then
			self:setRulesChannelId(resource.rulesChannelId)
		end

		if resource.publicUpdatesChannelId then
			self:setPublicUpdatesChannelId(resource.publicUpdatesChannelId)
		end

		if resource.preferredLocale then
			self:setPreferredLocale(resource.preferredLocale)
		end

		if resource.features then
			for _, feature: apiTypes.GuildFeature in resource.features do
				self:addFeature(feature)
			end
		end

		if resource.description then
			self:setDescription(resource.description)
		end

		if resource.premiumProgressBarEnabled then
			self:setPremiumProgressBarEnabled(resource.premiumProgressBarEnabled)
		end

		if resource.safetyAlertsChannelId then
			self:setSafetyAlertsChannelId(resource.safetyAlertsChannelId)
		end
	end

	return self
end

export type Guild = typeof(Guild.Prototype) & {
	name: string?,
	verificationLevel: apiTypes.VerificationLevel,
	defaultMessageNotifications: apiTypes.DefaultMessageNotification,
	explicitContentFilter: apiTypes.ExplicitContentFilterLevel,
	afkChannelId: apiTypes.Snowflake?,
	afkTimeout: number?,
	icon: string?,
	ownerId: apiTypes.Snowflake?,
	splash: string?,
	discoverySplash: string?,
	banner: string?,
	systemChannelId: apiTypes.Snowflake?,
	systemChannelFlags: number?,
	rulesChannelId: apiTypes.Snowflake?,
	publicUpdatesChannelId: apiTypes.Snowflake?,
	preferredLocale: apiTypes.LanguageLocales?,
	features: { apiTypes.GuildFeature },
	description: string?,
	premiumProgressBarEnabled: boolean?,
	safetyAlertsChannelId: apiTypes.Snowflake?,
}

export type JSON = typeof(Guild.Prototype.build(nil :: any))

return Guild.Interface
