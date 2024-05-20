--[=[
	@class DiscordLuau

	A Discord API wrapper written in Luau, expected to run under the Lune runtime.
]=]

-- Builders
local ApplicationCommand = require("Classes/Builders/ApplicationCommand")
local ApplicationCommandOption = require("Classes/Builders/ApplicationCommandOption")

local DiscordActivity = require("Classes/Builders/DiscordActivity")
local DiscordAutomoderationRule = require("Classes/Builders/DiscordAutomoderationRule")
local DiscordEmbed = require("Classes/Builders/DiscordEmbed")
local DiscordIntents = require("Classes/Builders/DiscordIntents")
local DiscordModal = require("Classes/Builders/DiscordModal")
local DiscordPermissions = require("Classes/Builders/DiscordPermissions")
local DiscordPresence = require("Classes/Builders/DiscordPresence")
local DiscordSettings = require("Classes/Builders/DiscordSettings")

-- Objects
local DiscordApplication = require("Classes/Objects/DiscordApplication")
local DiscordAutomoderationRule = require("Classes/Objects/DiscordAutomoderationRule")
local DiscordCache = require("Classes/Objects/DiscordCache")
local DiscordChannel = require("Classes/Objects/DiscordChannel")
local DiscordEmoji = require("Classes/Objects/DiscordEmoji")
local DiscordGuild = require("Classes/Objects/DiscordGuild")
local DiscordGuildMember = require("Classes/Objects/DiscordGuildMember")
local DiscordGuildRole = require("Classes/Objects/DiscordGuildRole")
local DiscordInteraction = require("Classes/Objects/DiscordInteraction")
local DiscordInvite = require("Classes/Objects/DiscordInvite")
local DiscordMessage = require("Classes/Objects/DiscordMessage")
local DiscordTextChannel = require("Classes/Objects/DiscordTextChannel")
local DiscordVoiceChannel = require("Classes/Objects/DiscordVoiceChannel")
local DiscordUser = require("Classes/Objects/DiscordUser")

-- Client
local DiscordClient = require("Classes/DiscordClient")

local DiscordLuau = {}

--#region
--#MARK: Discord-Luau Builders

export type ApplicationCommandBuilder = ApplicationCommand.ApplicationCommand
DiscordLuau.ApplicationCommand = ApplicationCommand

export type ApplicationCommandOptionBuilder = ApplicationCommandOption.ApplicationCommandOptions
DiscordLuau.ApplicationCommandOption = ApplicationCommandOption

export type DiscordActivityBuilder = DiscordActivity.DiscordActivity
DiscordLuau.DiscordActivity = DiscordActivity

export type DiscordAutomoderationRuleBuilder = DiscordAutomoderationRule.DiscordAutomoderationRule
DiscordLuau.DiscordAutomoderationRule = DiscordAutomoderationRule

export type DiscordEmbedBuilder = DiscordEmbed.DiscordEmbed
DiscordLuau.DiscordEmbed = DiscordEmbed

export type DiscordIntentsBuilder = DiscordIntents.DiscordIntents
DiscordLuau.DiscordIntents = DiscordIntents

export type DiscordModalBuilder = DiscordModal.DiscordModal
DiscordLuau.DiscordModal = DiscordModal

export type DiscordPermissionsBuilder = DiscordPermissions.DiscordPermissions
DiscordLuau.DiscordPermissions = DiscordPermissions

export type DiscordPresenceBuilder = DiscordPresence.DiscordPresence
DiscordLuau.DiscordPresence = DiscordPresence

export type DiscordSettingsBuilder = DiscordSettings.DiscordSettings
DiscordLuau.DiscordSettings = DiscordSettings

--#endregion

--#region
--#MARK: Discord-Luau Client
export type DiscordClient = DiscordClient.DiscordClient
DiscordLuau.DiscordClient = DiscordClient
--#endregion

--#region
--#MARK: Discord-Luau Type Exports
export type DiscordApplication = DiscordApplication.DiscordApplication
export type DiscordAutomoderationRule = DiscordAutomoderationRule.DiscordAutomoderationRule
export type DiscordCache = DiscordCache.DiscordCache
export type DiscordChannel = DiscordChannel.DiscordChannel
export type DiscordEmoji = DiscordEmoji.DiscordEmoji
export type DiscordGuild = DiscordGuild.DiscordGuild
export type DiscordGuildMember = DiscordGuildMember.DiscordGuildMember
export type DiscordGuildRole = DiscordGuildRole.DiscordGuildRole
export type DiscordInteraction = DiscordInteraction.DiscordInteraction
export type DiscordInvite = DiscordInvite.DiscordInvite
export type DiscordMessage = DiscordMessage.DiscordMessage
export type DiscordTextChannel = DiscordTextChannel.DiscordTextChannel
export type DiscordVoiceChannel = DiscordVoiceChannel.DiscordVoiceChannel
export type DiscordUser = DiscordUser.DiscordUser
--#endregion

return DiscordLuau
