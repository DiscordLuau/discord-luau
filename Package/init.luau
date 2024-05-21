--[=[
	@class DiscordLuau

	A Discord API wrapper written in Luau, expected to run under the Lune runtime.
]=]

-- Builders
local ApplicationCommandBuilder = require("Classes/Builders/ApplicationCommandBuilder")
local ApplicationCommandOptionBuilder = require("Classes/Builders/ApplicationCommandOptionBuilder")

local DiscordActivityBuilder = require("Classes/Builders/DiscordActivityBuilder")
local DiscordAutomoderationRuleBuilder = require("Classes/Builders/DiscordAutomoderationRuleBuilder")
local DiscordEmbedBuilder = require("Classes/Builders/DiscordEmbedBuilder")
local DiscordIntentsBuilder = require("Classes/Builders/DiscordIntentsBuilder")
local DiscordModalBuilder = require("Classes/Builders/DiscordModalBuilder")
local DiscordPermissionsBuilder = require("Classes/Builders/DiscordPermissionsBuilder")
local DiscordPresenceBuilder = require("Classes/Builders/DiscordPresenceBuilder")
local DiscordSettingsBuilder = require("Classes/Builders/DiscordSettingsBuilder")
local DiscordMessageBuilder = require("Classes/Builders/DiscordMessageBuilder")

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

-- Components
local ActionRowBuilder = require("Classes/Interface/ActionRowBuilder")
local ButtonBuilder = require("Classes/Interface/ButtonBuilder")
local SelectionBuilder = require("Classes/Interface/SelectionBuilder")
local TextInputBuilder = require("Classes/Interface/TextInputBuilder")

-- Client
local DiscordClient = require("Classes/DiscordClient")

local DiscordLuau = {}

--#region
--#MARK: Discord-Luau Components

DiscordLuau.Components = {}

export type ActionRowBuilder = ActionRowBuilder.ActionRowBuilder
DiscordLuau.Components.ActionRowBuilder = ActionRowBuilder

export type ButtonBuilder = ButtonBuilder.ButtonBuilder
DiscordLuau.Components.ButtonBuilder = ButtonBuilder

export type SelectionBuilder = SelectionBuilder.SelectionBuilder
DiscordLuau.Components.SelectionBuilder = SelectionBuilder

export type TextInputBuilder = TextInputBuilder.TextInputBuilder
DiscordLuau.Components.TextInputBuilder = TextInputBuilder

--#endregion

--#region
--#MARK: Discord-Luau Builders

export type DiscordMessageBuilder = DiscordMessageBuilder.DiscordMessageBuilder
DiscordLuau.DiscordMessageBuilder = DiscordMessageBuilder

export type ApplicationCommandBuilder = ApplicationCommandBuilder.ApplicationCommandBuilder
DiscordLuau.ApplicationCommandBuilder = ApplicationCommandBuilder

export type ApplicationCommandOptionBuilder = ApplicationCommandOptionBuilder.ApplicationCommandOptionBuilder
DiscordLuau.ApplicationCommandOptionBuilder = ApplicationCommandOptionBuilder

export type DiscordActivityBuilder = DiscordActivityBuilder.DiscordActivityBuilder
DiscordLuau.DiscordActivityBuilder = DiscordActivityBuilder

export type DiscordAutomoderationRuleBuilder = DiscordAutomoderationRuleBuilder.DiscordAutomoderationRuleBuilder
DiscordLuau.DiscordAutomoderationRuleBuilder = DiscordAutomoderationRuleBuilder

export type DiscordEmbedBuilder = DiscordEmbedBuilder.DiscordEmbedBuilder
DiscordLuau.DiscordEmbedBuilder = DiscordEmbedBuilder

export type DiscordIntentsBuilder = DiscordIntentsBuilder.DiscordIntentsBuilder
DiscordLuau.DiscordIntentsBuilder = DiscordIntentsBuilder

export type DiscordModalBuilder = DiscordModalBuilder.DiscordModalBuilder
DiscordLuau.DiscordModalBuilder = DiscordModalBuilder

export type DiscordPermissionsBuilder = DiscordPermissionsBuilder.DiscordPermissionsBuilder
DiscordLuau.DiscordPermissionsBuilder = DiscordPermissionsBuilder

export type DiscordPresenceBuilder = DiscordPresenceBuilder.DiscordPresenceBuilder
DiscordLuau.DiscordPresenceBuilder = DiscordPresenceBuilder

export type DiscordSettingsBuilder = DiscordSettingsBuilder.DiscordSettingsBuilder
DiscordLuau.DiscordSettingsBuilder = DiscordSettingsBuilder

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
