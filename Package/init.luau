--[=[
	@class DiscordLuau

	A Discord API wrapper written in Luau, expected to run under the Lune runtime.
]=]

-- Builders
local CommandBuilder = require("@Builders/CommandBuilder")
local CommandOptionBuilder = require("@Builders/CommandOptionBuilder")
local ActivityBuilder = require("@Builders/ActivityBuilder")
local AutomoderationRuleBuilder = require("@Builders/AutomoderationRuleBuilder")
local ChannelBuilder = require("@Builders/ChannelBuilder")
local EmbedBuilder = require("@Builders/EmbedBuilder")
local IntentsBuilder = require("@Builders/IntentsBuilder")
local ModalBuilder = require("@Builders/ModalBuilder")
local PermissionsBuilder = require("@Builders/PermissionsBuilder")
local PresenceBuilder = require("@Builders/PresenceBuilder")
local SettingsBuilder = require("@Builders/SettingsBuilder")
local MessageBuilder = require("@Builders/MessageBuilder")
local AttachmentBuilder = require("@Builders/AttachmentBuilder")

local OnboardingBuilder = require("@Builders/OnboardingBuilder")
local OnboardingPromptBuilder = require("@Builders/OnboardingPromptBuilder")
local OnboardingPromptOptionBuilder = require("@Builders/OnboardingPromptOptionBuilder")
local WelcomeScreenBuilder = require("@Builders/WelcomeScreenBuilder")

-- Objects
local DiscordApplication = require("@Objects/DiscordApplication")
local DiscordAutomoderationRule = require("@Objects/DiscordAutomoderationRule")
local DiscordCache = require("@Objects/DiscordCache")
local DiscordChannel = require("@Objects/DiscordChannel")
local DiscordEmoji = require("@Objects/DiscordEmoji")
local DiscordGuild = require("@Objects/DiscordGuild")
local DiscordGuildMember = require("@Objects/DiscordGuildMember")
local DiscordGuildRole = require("@Objects/DiscordGuildRole")
local DiscordInteraction = require("@Objects/DiscordInteraction")
local DiscordInvite = require("@Objects/DiscordInvite")
local DiscordMessage = require("@Objects/DiscordMessage")
local GuildAnnouncementChannel = require("@Objects/GuildAnnouncementChannel")
local GuildAnnouncementThreadChannel = require("@Objects/GuildAnnouncementThreadChannel")
local GuildCategoryChannel = require("@Objects/GuildCategoryChannel")
local GuildDirectoryChannel = require("@Objects/GuildDirectoryChannel")
local GuildForumChannel = require("@Objects/GuildForumChannel")
local GuildMediaChannel = require("@Objects/GuildMediaChannel")
local GuildPrivateThreadChannel = require("@Objects/GuildPrivateThreadChannel")
local GuildPublicThreadChannel = require("@Objects/GuildPublicThreadChannel")
local GuildStageVoiceChannel = require("@Objects/GuildStageVoiceChannel")
local UserDMChannel = require("@Objects/UserDMChannel")
local UserGroupChannel = require("@Objects/UserGroupChannel")
local DiscordUser = require("@Objects/DiscordUser")
local GuildTextChannel = require("@Objects/GuildTextChannel")
local GuildVoiceChannel = require("@Objects/GuildVoiceChannel")

-- Components
local ActionRowBuilder = require("@Builders/Interface/ActionRowBuilder")
local ButtonBuilder = require("@Builders/Interface/ButtonBuilder")
local SelectionBuilder = require("@Builders/Interface/SelectionBuilder")
local TextInputBuilder = require("@Builders/Interface/TextInputBuilder")

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

export type OnboardingBuilder = OnboardingBuilder.OnboardingBuilder
DiscordLuau.OnboardingBuilder = OnboardingBuilder
--[=[
	@prop OnboardingBuilder Builders.OnboardingBuilder
	@within DiscordLuau
]=]

export type OnboardingPromptBuilder = OnboardingPromptBuilder.OnboardingPromptBuilder
DiscordLuau.OnboardingPromptBuilder = OnboardingPromptBuilder
--[=[
	@prop OnboardingPromptBuilder Builders.OnboardingPromptBuilder
	@within DiscordLuau
]=]

export type OnboardingPromptOptionBuilder = OnboardingPromptOptionBuilder.OnboardingPromptOptionBuilder
DiscordLuau.OnboardingPromptOptionBuilder = OnboardingPromptOptionBuilder
--[=[
	@prop OnboardingPromptOptionBuilder Builders.OnboardingPromptOptionBuilder
	@within DiscordLuau
]=]

export type WelcomeScreenBuilder = WelcomeScreenBuilder.WelcomeScreenBuilder
DiscordLuau.WelcomeScreenBuilder = WelcomeScreenBuilder
--[=[
	@prop WelcomeScreenBuilder Builders.WelcomeScreenBuilder
	@within DiscordLuau
]=]

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
