--[=[
	@class Builders.Guild
	@__index Prototype

	Implementation of Discord's Guild object as a Luau builder.

	See Discord's documentation for more information about the allow and deny fields:

	https://discord.com/developers/docs/resources/guild
]=]

local apiTypes = require("../../lune_packages/api_types")

local Guild = {}

Guild.Prototype = {}
Guild.Interface = {}

--[=[
	@within Builders.Guild
	Set the name for this guild.
]=]
function Guild.Prototype.setName(self: Guild, name: string): Guild
	assert(#name <= 100, "Name must be less than 100 characters")
	assert(#name > 1, "Name must be greater than 1 characters")

	self.name = name

	return self
end

--[=[
	@within Builders.Guild
	Set the explicit verification level for this guild.
]=]
function Guild.Prototype.setVerificationLevel(self: Guild, verificationLevel: apiTypes.VerificationLevel): Guild
	assert(apiTypes.guild.VerificationLevel[verificationLevel], "Invalid verification level")

	self.verificationLevel = verificationLevel

	return self
end

--[=[
	@within Builders.Guild
	Set the explicit default message notifications for this guild.
]=]
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

--[=[
	@within Builders.Guild
	Set the explicit content filter level for this guild.
]=]
function Guild.Prototype.setExplicitContentFilter(
	self: Guild,
	explicitContentFilter: apiTypes.ExplicitContentFilterLevel
): Guild
	assert(apiTypes.guild.ExplicitContentFilterLevel[explicitContentFilter], "Invalid explicitContentFilter level")

	self.explicitContentFilter = explicitContentFilter

	return self
end

--[=[
	@within Builders.Guild
	Set the id for the AFK channel.
]=]
function Guild.Prototype.setAfkChannelId(self: Guild, afkChannelId: apiTypes.Snowflake): Guild
	self.afkChannelId = afkChannelId

	return self
end

--[=[
	@within Builders.Guild
	Set the AFK timeout in seconds. Can be one of: 60, 300, 900, 1800, 3600.
]=]
function Guild.Prototype.setAfkTimeout(self: Guild, afkTimeout: number): Guild
	self.afkTimeout = afkTimeout

	return self
end

--[=[
	@within Builders.Guild
	Set the base64 1024x1024 PNG/JPEG/GIF image for the guild icon.
]=]
function Guild.Prototype.setIcon(self: Guild, source: string): Guild
	self.icon = source

	return self
end

--[=[
	@within Builders.Guild
	Set the user ID to transfer guild ownership to (must be owner).
]=]
function Guild.Prototype.setOwnerId(self: Guild, ownerId: apiTypes.Snowflake): Guild
	self.ownerId = ownerId

	return self
end

--[=[
	@within Builders.Guild
	Set the base64 16:9 PNG/JPEG image for the guild splash.
]=]
function Guild.Prototype.setSplash(self: Guild, source: string): Guild
	self.splash = source

	return self
end

--[=[
	@within Builders.Guild
	Set the base64 16:9 PNG/JPEG image for the discovery splash of the guild.
]=]
function Guild.Prototype.setDiscoverySplash(self: Guild, source: string): Guild
	self.discoverySplash = source

	return self
end

--[=[
	@within Builders.Guild
	Set the base64 16:9 PNG/JPEG/GIF image for the guild banner.
]=]
function Guild.Prototype.setBanner(self: Guild, source: string): Guild
	self.banner = source

	return self
end

--[=[
	@within Builders.Guild
	Set the ID of the system channel.
]=]
function Guild.Prototype.setSystemChannelId(self: Guild, systemChannelId: apiTypes.Snowflake): Guild
	self.systemChannelId = systemChannelId

	return self
end

--[=[
	@within Builders.Guild
	Set the system channel flags.
]=]
function Guild.Prototype.setSystemChannelFlags(self: Guild, systemChannelFlags: number): Guild
	self.systemChannelFlags = systemChannelFlags

	return self
end

--[=[
	@within Builders.Guild
	Set the ID of the rules channel.
]=]
function Guild.Prototype.setRulesChannelId(self: Guild, rulesChannelId: apiTypes.Snowflake): Guild
	self.rulesChannelId = rulesChannelId

	return self
end

--[=[
	@within Builders.Guild
	Set the ID of the public updates channel.
]=]
function Guild.Prototype.setPublicUpdatesChannelId(self: Guild, publicUpdatesChannelId: apiTypes.Snowflake): Guild
	self.publicUpdatesChannelId = publicUpdatesChannelId

	return self
end

--[=[
	@within Builders.Guild
	Set the preferred locale of the guild.
]=]
function Guild.Prototype.setPreferredLocale(self: Guild, preferredLocale: apiTypes.LanguageLocales): Guild
	self.preferredLocale = preferredLocale

	return self
end

--[=[
	@within Builders.Guild
	Enable a specific guild feature.
]=]
function Guild.Prototype.addFeature(self: Guild, feature: apiTypes.GuildFeature): Guild
	table.insert(self.features, feature)

	return self
end

--[=[
	@within Builders.Guild
	Set the description for the guild.
]=]
function Guild.Prototype.setDescription(self: Guild, description: string): Guild
	self.description = description

	return self
end

--[=[
	@within Builders.Guild
	Set whether the guild's boost progress bar should be enabled.
]=]
function Guild.Prototype.setPremiumProgressBarEnabled(self: Guild, premiumProgressBarEnabled: boolean): Guild
	self.premiumProgressBarEnabled = premiumProgressBarEnabled

	return self
end

--[=[
	@within Builders.Guild
	Set the ID of the safety alerts channel.
]=]
function Guild.Prototype.setSafetyAlertsChannelId(self: Guild, safetyAlertsChannelId: apiTypes.Snowflake): Guild
	self.safetyAlertsChannelId = safetyAlertsChannelId

	return self
end

--[=[
	@within Builders.Guild
	Responsible for building the Guild JSON that can be parsed by the Discord API.
]=]
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

--[=[
	@within Builders.Guild
	Construct a new Guild object.
]=]
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
			--[=[
				@prop name string?
				@within Builders.Guild
				The name of the guild.
			]=]

			--[=[
				@prop verificationLevel Classes.VerificationLevel
				@within Builders.Guild
				Verification level setting for the guild.
			]=]

			--[=[
				@prop defaultMessageNotifications Classes.DefaultMessageNotification
				@within Builders.Guild
				Default message notification level.
			]=]

			--[=[
				@prop explicitContentFilter Classes.ExplicitContentFilterLevel
				@within Builders.Guild
				Explicit content filter level setting.
			]=]

			--[=[
				@prop afkChannelId string?
				@within Builders.Guild
				ID of the AFK voice channel.
			]=]

			--[=[
				@prop afkTimeout number?
				@within Builders.Guild
				AFK timeout duration in seconds.
			]=]

			--[=[
				@prop icon string?
				@within Builders.Guild
				Base64 encoded icon for the guild.
			]=]

			--[=[
				@prop ownerId string?
				@within Builders.Guild
				User ID of the owner of the guild.
			]=]

			--[=[
				@prop splash string?
				@within Builders.Guild
				Base64 splash image for the guild.
			]=]

			--[=[
				@prop discoverySplash string?
				@within Builders.Guild
				Base64 discovery splash image for the guild.
			]=]

			--[=[
				@prop banner string?
				@within Builders.Guild
				Base64 banner image for the guild.
			]=]

			--[=[
				@prop systemChannelId string?
				@within Builders.Guild
				ID of the system messages channel.
			]=]

			--[=[
				@prop systemChannelFlags number?
				@within Builders.Guild
				Flags for the system channel.
			]=]

			--[=[
				@prop rulesChannelId string?
				@within Builders.Guild
				ID of the rules channel.
			]=]

			--[=[
				@prop publicUpdatesChannelId string?
				@within Builders.Guild
				ID of the public updates channel.
			]=]

			--[=[
				@prop preferredLocale Classes.LanguageLocales?
				@within Builders.Guild
				Preferred language/locale for the guild.
			]=]

			--[=[
				@prop features { Builders.GuildFeature }
				@within Builders.Guild
				List of enabled guild features.
			]=]
			features = {},

			--[=[
				@prop description string?
				@within Builders.Guild
				Description of the guild.
			]=]

			--[=[
				@prop premiumProgressBarEnabled boolean?
				@within Builders.Guild
				Whether boost progress bar is enabled.
			]=]

			--[=[
				@prop safetyAlertsChannelId string?
				@within Builders.Guild
				ID of the safety alerts channel.
			]=]
		} :: Guild,
		{ __index = Guild.Prototype }
	)

	-- Initialization logic
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
