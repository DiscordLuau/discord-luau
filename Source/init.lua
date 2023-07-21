local DiscordLuaU = {}

DiscordLuaU.Internal = {}
DiscordLuaU.Interface = {
	Internal = DiscordLuaU.Internal,
}

DiscordLuaU.Interface.DiscordClient = require("Classes/DiscordClient")
DiscordLuaU.Interface.DiscordIntents = require("Classes/DiscordIntents")
DiscordLuaU.Interface.DiscordPresence = require("Classes/DiscordPresence")
DiscordLuaU.Interface.DiscordActivity = require("Classes/DiscordActivity")
DiscordLuaU.Interface.DiscordSettings = require("Classes/DiscordSettings")

return DiscordLuaU.Interface
