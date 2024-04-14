local DiscordLuau = require("..")

local DiscordSettings = DiscordLuau.DiscordSettings.new("")
local DiscordClient = DiscordLuau.DiscordClient.new(DiscordSettings)

DiscordClient:connectAsync()