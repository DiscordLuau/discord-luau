--[=[
	@class DiscordLuau

	A Discord API wrapper written in Luau, expected to run under the Lune runtime.
]=]

-- Builders
local CommandBuilder = require("Classes/Builders/CommandBuilder")
local CommandOptionBuilder = require("Classes/Builders/CommandOptionBuilder")

local ActivityBuilder = require("Classes/Builders/ActivityBuilder")
local AutomoderationRuleBuilder = require("Classes/Builders/AutomoderationRuleBuilder")
local ChannelBuilder = require("Classes/Builders/ChannelBuilder")
local EmbedBuilder = require("Classes/Builders/EmbedBuilder")
local IntentsBuilder = require("Classes/Builders/IntentsBuilder")
local ModalBuilder = require("Classes/Builders/ModalBuilder")
local PermissionsBuilder = require("Classes/Builders/PermissionsBuilder")
local PresenceBuilder = require("Classes/Builders/PresenceBuilder")
local SettingsBuilder = require("Classes/Builders/SettingsBuilder")
local MessageBuilder = require("Classes/Builders/MessageBuilder")
local AttachmentBuilder = require("Classes/Builders/AttachmentBuilder")

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
local GuildAnnouncementChannel = require("Classes/Objects/GuildAnnouncementChannel")
local GuildAnnouncementThreadChannel = require("Classes/Objects/GuildAnnouncementThreadChannel")
local GuildCategoryChannel = require("Classes/Objects/GuildCategoryChannel")
local GuildDirectoryChannel = require("Classes/Objects/GuildDirectoryChannel")
local GuildForumChannel = require("Classes/Objects/GuildForumChannel")
local GuildMediaChannel = require("Classes/Objects/GuildMediaChannel")
local GuildPrivateThreadChannel = require("Classes/Objects/GuildPrivateThreadChannel")
local GuildPublicThreadChannel = require("Classes/Objects/GuildPublicThreadChannel")
local GuildStageVoiceChannel = require("Classes/Objects/GuildStageVoiceChannel")
local UserDMChannel = require("Classes/Objects/UserDMChannel")
local UserGroupChannel = require("Classes/Objects/UserGroupChannel")
local DiscordUser = require("Classes/Objects/DiscordUser")
local GuildTextChannel = require("Classes/Objects/GuildTextChannel")
local GuildVoiceChannel = require("Classes/Objects/GuildVoiceChannel")

-- Components
local ActionRowBuilder = require("Classes/Builders/Interface/ActionRowBuilder")
local ButtonBuilder = require("Classes/Builders/Interface/ButtonBuilder")
local SelectionBuilder = require("Classes/Builders/Interface/SelectionBuilder")
local TextInputBuilder = require("Classes/Builders/Interface/TextInputBuilder")

-- Client
local DiscordClient = require("Classes/DiscordClient")

local DiscordLuau = {}

--#region
--#MARK: Discord-Luau Components

DiscordLuau.Components = {}

export type ActionRowBuilder = ActionRowBuilder.ActionRowBuilder
DiscordLuau.ActionRowBuilder = ActionRowBuilder
--[=[
	@prop ActionRowBuilder Builders.Interface.ActionRowBuilder
	@within DiscordLuau
]=]

export type ButtonBuilder = ButtonBuilder.ButtonBuilder
DiscordLuau.ButtonBuilder = ButtonBuilder
--[=[
	@prop ButtonBuilder Builders.Interface.ButtonBuilder
	@within DiscordLuau
]=]

export type SelectionBuilder = SelectionBuilder.SelectionBuilder
DiscordLuau.SelectionBuilder = SelectionBuilder
--[=[
	@prop SelectionBuilder Builders.Interface.SelectionBuilder
	@within DiscordLuau
]=]

export type TextInputBuilder = TextInputBuilder.TextInputBuilder
DiscordLuau.TextInputBuilder = TextInputBuilder
--[=[
	@prop TextInputBuilder Builders.Interface.TextInputBuilder
	@within DiscordLuau
]=]

--#endregion

--#region
--#MARK: Discord-Luau Builders

export type MessageBuilder = MessageBuilder.MessageBuilder
DiscordLuau.MessageBuilder = MessageBuilder
--[=[
	@prop MessageBuilder Builders.MessageBuilder
	@within DiscordLuau
]=]

export type ChannelBuilder = ChannelBuilder.ChannelBuilder
DiscordLuau.ChannelBuilder = ChannelBuilder
--[=[
	@prop ChannelBuilder Builders.ChannelBuilder
	@within DiscordLuau
]=]

export type AttachmentBuilder = AttachmentBuilder.AttachmentBuilder
DiscordLuau.AttachmentBuilder = AttachmentBuilder
--[=[
	@prop AttachmentBuilder Builders.AttachmentBuilder
	@within DiscordLuau
]=]

export type CommandBuilder = CommandBuilder.CommandBuilder
DiscordLuau.CommandBuilder = CommandBuilder
--[=[
	@prop CommandBuilder Builders.CommandBuilder
	@within DiscordLuau
]=]

export type CommandOptionBuilder = CommandOptionBuilder.CommandOptionBuilder
DiscordLuau.CommandOptionBuilder = CommandOptionBuilder
--[=[
	@prop CommandOptionBuilder Builders.CommandOptionBuilder
	@within DiscordLuau
]=]

export type ActivityBuilder = ActivityBuilder.ActivityBuilder
DiscordLuau.ActivityBuilder = ActivityBuilder
--[=[
	@prop ActivityBuilder Builders.ActivityBuilder
	@within DiscordLuau
]=]

export type AutomoderationRuleBuilder = AutomoderationRuleBuilder.AutomoderationRuleBuilder
DiscordLuau.AutomoderationRuleBuilder = AutomoderationRuleBuilder
--[=[
	@prop AutomoderationRuleBuilder Builders.AutomoderationRuleBuilder
	@within DiscordLuau
]=]

export type EmbedBuilder = EmbedBuilder.EmbedBuilder
DiscordLuau.EmbedBuilder = EmbedBuilder
--[=[
	@prop EmbedBuilder Builders.EmbedBuilder
	@within DiscordLuau
]=]

export type IntentsBuilder = IntentsBuilder.IntentsBuilder
DiscordLuau.IntentsBuilder = IntentsBuilder
--[=[
	@prop IntentsBuilder Builders.IntentsBuilder
	@within DiscordLuau
]=]

export type ModalBuilder = ModalBuilder.ModalBuilder
DiscordLuau.ModalBuilder = ModalBuilder
--[=[
	@prop ModalBuilder Builders.ModalBuilder
	@within DiscordLuau
]=]

export type PermissionsBuilder = PermissionsBuilder.PermissionsBuilder
DiscordLuau.PermissionsBuilder = PermissionsBuilder
--[=[
	@prop PermissionsBuilder Builders.PermissionsBuilder
	@within DiscordLuau
]=]

export type PresenceBuilder = PresenceBuilder.PresenceBuilder
DiscordLuau.PresenceBuilder = PresenceBuilder
--[=[
	@prop PresenceBuilder Builders.PresenceBuilder
	@within DiscordLuau
]=]

export type SettingsBuilder = SettingsBuilder.SettingsBuilder
DiscordLuau.SettingsBuilder = SettingsBuilder
--[=[
	@prop SettingsBuilder Builders.SettingsBuilder
	@within DiscordLuau
]=]

--#endregion

--#region
--#MARK: Discord-Luau Client

export type DiscordClient = DiscordClient.DiscordClient
DiscordLuau.DiscordClient = DiscordClient
--[=[
	@prop DiscordClient DiscordClient
	@within DiscordLuau
]=]

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
export type DiscordUser = DiscordUser.DiscordUser
export type GuildAnnouncementChannel = GuildAnnouncementChannel.GuildAnnouncementChannel
export type GuildAnnouncementThreadChannel = GuildAnnouncementThreadChannel.GuildAnnouncementThreadChannel
export type GuildCategoryChannel = GuildCategoryChannel.GuildCategoryChannel
export type GuildDirectoryChannel = GuildDirectoryChannel.GuildDirectoryChannel
export type GuildForumChannel = GuildForumChannel.GuildForumChannel
export type GuildMediaChannel = GuildMediaChannel.GuildMediaChannel
export type GuildPrivateThreadChannel = GuildPrivateThreadChannel.GuildPrivateThreadChannel
export type GuildPublicThreadChannel = GuildPublicThreadChannel.GuildPublicThreadChannel
export type GuildStageVoiceChannel = GuildStageVoiceChannel.GuildStageVoiceChannel
export type UserDMChannel = UserDMChannel.UserDMChannel
export type UserGroupChannel = UserGroupChannel.UserGroupChannel
export type GuildTextChannel = GuildTextChannel.GuildTextChannel
export type GuildVoiceChannel = GuildVoiceChannel.GuildVoiceChannel
--#endregion

return DiscordLuau
