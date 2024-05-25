--[=[
	@class DiscordLuau

	A Discord API wrapper written in Luau, expected to run under the Lune runtime.
]=]

-- Builders
local CommandBuilder = require("Classes/Builders/CommandBuilder")
local CommandOptionBuilder = require("Classes/Builders/CommandOptionBuilder")

local ActivityBuilder = require("Classes/Builders/ActivityBuilder")
local AutomoderationRuleBuilder = require("Classes/Builders/AutomoderationRuleBuilder")
local EmbedBuilder = require("Classes/Builders/EmbedBuilder")
local IntentsBuilder = require("Classes/Builders/IntentsBuilder")
local ModalBuilder = require("Classes/Builders/ModalBuilder")
local PermissionsBuilder = require("Classes/Builders/PermissionsBuilder")
local PresenceBuilder = require("Classes/Builders/PresenceBuilder")
local SettingsBuilder = require("Classes/Builders/SettingsBuilder")
local MessageBuilder = require("Classes/Builders/MessageBuilder")

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

export type MessageBuilder = MessageBuilder.MessageBuilder
DiscordLuau.MessageBuilder = MessageBuilder

export type CommandBuilder = CommandBuilder.CommandBuilder
DiscordLuau.CommandBuilder = CommandBuilder

export type CommandOptionBuilder = CommandOptionBuilder.CommandOptionBuilder
DiscordLuau.CommandOptionBuilder = CommandOptionBuilder

export type ActivityBuilder = ActivityBuilder.ActivityBuilder
DiscordLuau.ActivityBuilder = ActivityBuilder

export type AutomoderationRuleBuilder = AutomoderationRuleBuilder.AutomoderationRuleBuilder
DiscordLuau.AutomoderationRuleBuilder = AutomoderationRuleBuilder

export type EmbedBuilder = EmbedBuilder.EmbedBuilder
DiscordLuau.EmbedBuilder = EmbedBuilder

export type IntentsBuilder = IntentsBuilder.IntentsBuilder
DiscordLuau.IntentsBuilder = IntentsBuilder

export type ModalBuilder = ModalBuilder.ModalBuilder
DiscordLuau.ModalBuilder = ModalBuilder

export type PermissionsBuilder = PermissionsBuilder.PermissionsBuilder
DiscordLuau.PermissionsBuilder = PermissionsBuilder

export type PresenceBuilder = PresenceBuilder.PresenceBuilder
DiscordLuau.PresenceBuilder = PresenceBuilder

export type SettingsBuilder = SettingsBuilder.SettingsBuilder
DiscordLuau.SettingsBuilder = SettingsBuilder

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
