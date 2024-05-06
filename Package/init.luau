--[=[
	@class Discord-Luau

	A Discord API wrapper written in Luau, expected to run under the Lune runtime.
]=]

local DiscordLuau = {}

--[=[
	@prop Components { }
	@within Discord-Luau

	Contains all interface component objects.
]=]
DiscordLuau.Components = {
	ActionRowComponent = require("Classes/Interface/ActionRowComponent"),
	ButtonComponent = require("Classes/Interface/ButtonComponent"),
	SelectionComponent = require("Classes/Interface/SelectionComponent"),
	TextInputComponent = require("Classes/Interface/TextInputComponent")
}

--[=[
	@prop DiscordIntents DiscordIntents
	@within Discord-Luau
]=]
DiscordLuau.DiscordIntents = require("Classes/DiscordIntents")

--[=[
	@prop DiscordSettings DiscordSettings
	@within Discord-Luau
]=]
DiscordLuau.DiscordSettings = require("Classes/DiscordSettings")

--[=[
	@prop DiscordClient DiscordClient
	@within Discord-Luau
]=]
DiscordLuau.DiscordClient = require("Classes/DiscordClient")

--[=[
	@prop DiscordActivity DiscordActivity
	@within Discord-Luau
]=]
DiscordLuau.DiscordActivity = require("Classes/DiscordActivity")

--[=[
	@prop DiscordPermissions DiscordPermissions
	@within Discord-Luau
]=]
DiscordLuau.DiscordPermissions = require("Classes/DiscordPermissions")

--[=[
	@prop DiscordEmbed DiscordEmbed
	@within Discord-Luau
]=]
DiscordLuau.DiscordEmbed = require("Classes/DiscordEmbed")

--[=[
	@prop DiscordModal DiscordModal
	@within Discord-Luau
]=]
DiscordLuau.DiscordModal = require("Classes/DiscordModal")

--[=[
	@prop DiscordPresence DiscordPresence
	@within Discord-Luau
]=]
DiscordLuau.DiscordPresence = require("Classes/DiscordPresence")

--[=[
	@prop ApplicationCommand ApplicationCommand
	@within Discord-Luau
]=]
DiscordLuau.ApplicationCommand = require("Classes/ApplicationCommand")

--[=[
	@prop ApplicationCommandOption ApplicationCommandOption
	@within Discord-Luau
]=]
DiscordLuau.ApplicationCommandOption = require("Classes/ApplicationCommandOption")

local DiscordMessage = require("Types/DiscordMessage")
export type DiscordMessage = DiscordMessage.DiscordMessage

local DiscordGuild = require("Types/DiscordGuild")
export type DiscordGuild = DiscordGuild.DiscordGuild

local DiscordInteraction = require("Types/DiscordInteraction")
export type DiscordInteraction = DiscordInteraction.DiscordInteraction

return DiscordLuau
