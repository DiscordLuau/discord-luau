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

return DiscordLuau
