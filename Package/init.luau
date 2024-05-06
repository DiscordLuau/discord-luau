--[=[
	@class DiscordLuau

	A Discord API wrapper written in Luau, expected to run under the Lune runtime.
]=]

local DiscordLuau = {}

--[=[
	@prop Components { }
	@within DiscordLuau

	Contains all interface component objects.
]=]
DiscordLuau.Components = {
	ActionRowComponent = require("Classes/Interface/ActionRowComponent"),
	ButtonComponent = require("Classes/Interface/ButtonComponent"),
	SelectionComponent = require("Classes/Interface/SelectionComponent"),
	TextInputComponent = require("Classes/Interface/TextInputComponent")
}

--[=[
	@prop DiscordIntents !DiscordIntents
	@within DiscordLuau
]=]
DiscordLuau.DiscordIntents = require("Classes/DiscordIntents")

--[=[
	@prop DiscordSettings !DiscordSettings
	@within DiscordLuau
]=]
DiscordLuau.DiscordSettings = require("Classes/DiscordSettings")

--[=[
	@prop DiscordClient !DiscordClient
	@within DiscordLuau
]=]
DiscordLuau.DiscordClient = require("Classes/DiscordClient")

--[=[
	@prop DiscordActivity !DiscordActivity
	@within DiscordLuau
]=]
DiscordLuau.DiscordActivity = require("Classes/DiscordActivity")

--[=[
	@prop DiscordPermissions !DiscordPermissions
	@within DiscordLuau
]=]
DiscordLuau.DiscordPermissions = require("Classes/DiscordPermissions")

--[=[
	@prop DiscordEmbed !DiscordEmbed
	@within DiscordLuau
]=]
DiscordLuau.DiscordEmbed = require("Classes/DiscordEmbed")

--[=[
	@prop DiscordModal !DiscordModal
	@within DiscordLuau
]=]
DiscordLuau.DiscordModal = require("Classes/DiscordModal")

--[=[
	@prop DiscordPresence !DiscordPresence
	@within DiscordLuau
]=]
DiscordLuau.DiscordPresence = require("Classes/DiscordPresence")

--[=[
	@prop ApplicationCommand !ApplicationCommand
	@within DiscordLuau
]=]
DiscordLuau.ApplicationCommand = require("Classes/ApplicationCommand")

--[=[
	@prop ApplicationCommandOption !ApplicationCommandOption
	@within DiscordLuau
]=]
DiscordLuau.ApplicationCommandOption = require("Classes/ApplicationCommandOption")

local DiscordMessage = require("Types/DiscordMessage")
export type DiscordMessage = DiscordMessage.DiscordMessage

local DiscordGuild = require("Types/DiscordGuild")
export type DiscordGuild = DiscordGuild.DiscordGuild

local DiscordInteraction = require("Types/DiscordInteraction")
export type DiscordInteraction = DiscordInteraction.DiscordInteraction

return DiscordLuau
