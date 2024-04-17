--[=[
	@class Discord-Luau

	A Discord API wrapper written in Luau, expected to run under the Lune runtime.
]=]

local DiscordLuau = {}

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

return DiscordLuau
