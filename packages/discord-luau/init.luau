--[=[
	@class DiscordLuau

	A Discord API wrapper written in Luau, expected to run under the Lune runtime.
]=]

-- Builders
local CommandBuilder = require("@builders/command")
local CommandOptionBuilder = require("@builders/command/option")
local ActivityBuilder = require("@builders/activity")
local AutomoderationRuleBuilder = require("@builders/automoderationRule")
local ChannelBuilder = require("@builders/channel")
local EmbedBuilder = require("@builders/embed")
local IntentsBuilder = require("@builders/intents")
local ModalBuilder = require("@builders/modal")
local PermissionsBuilder = require("@builders/permissions")
local PresenceBuilder = require("@builders/presence")
local SettingsBuilder = require("@builders/settings")
local MessageBuilder = require("@builders/message")
local AttachmentBuilder = require("@builders/attachment")

local OnboardingBuilder = require("@builders/onboarding")
local OnboardingPromptBuilder = require("@builders/onboarding/prompt")
local OnboardingPromptOptionBuilder = require("@builders/onboarding/option")
local WelcomeScreenBuilder = require("@builders/welcomeScreen")

-- Objects
local DiscordApplication = require("@classes/application")
local DiscordAutomoderationRule = require("@classes/automoderationRule")
local DiscordCache = require("@classes/cache")
local DiscordChannel = require("@classes/channel")
local DiscordEmoji = require("@classes/emoji")
local DiscordGuild = require("@classes/guild")
local DiscordGuildMember = require("@classes/guild/member")
local DiscordGuildRole = require("@classes/guild/role")
local DiscordInteraction = require("@classes/interaction")
local DiscordInvite = require("@classes/invite")
local DiscordMessage = require("@classes/message")
local GuildAnnouncementChannel = require("@classes/channel/guild/text/announcement")
local GuildAnnouncementThreadChannel = require("@classes/channel/guild/thread/announcement")
local GuildCategoryChannel = require("@classes/channel/guild/category")
local GuildDirectoryChannel = require("@classes/channel/guild/text/directory")
local GuildForumChannel = require("@classes/channel/guild/forum")
local GuildMediaChannel = require("@classes/channel/guild/media")
local GuildPrivateThreadChannel = require("@classes/channel/guild/thread/private")
local GuildPublicThreadChannel = require("@classes/channel/guild/thread/public")
local GuildStageVoiceChannel = require("@classes/channel/guild/voice/stage")
local UserDMChannel = require("@classes/channel/user/directMessage")
local UserGroupChannel = require("@classes/channel/user/group")
local DiscordUser = require("@classes/user")
local GuildTextChannel = require("@classes/channel/guild/text")
local GuildVoiceChannel = require("@classes/channel/guild/voice")

-- Components
local ActionRowBuilder = require("@builders/interface/actionRow")
local ButtonBuilder = require("@builders/interface/button")
local SelectionBuilder = require("@builders/interface/selection")
local TextInputBuilder = require("@builders/interface/textInput")

-- Client
local DiscordClient = require("@classes/client")

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
