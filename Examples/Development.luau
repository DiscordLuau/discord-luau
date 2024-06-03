local DiscordLuau = require("..")
local Env = require("../.env")

local DiscordSettings = DiscordLuau.SettingsBuilder.new(Env.DISCORD_BOT_TOKEN)
local DiscordClient = DiscordLuau.DiscordClient.new(DiscordSettings)

-- DiscordClient:setVerbose(true)

DiscordClient.eventManager.onReady:connect(function()
	print(`🎉🎉 {DiscordClient.discordUser.username} is online! 🎉🎉`)

	print(DiscordClient:fetchChannelAsync("1048686561685946489"):await())
	print(DiscordClient:fetchChannelAsync("1239935584907169812"):await())
	print(DiscordClient:fetchChannelAsync("1239935584907169813"):await())
	print(DiscordClient:fetchChannelAsync("1246395956296155197"):await())
	print(DiscordClient:fetchChannelAsync("1134076704495775844"):await())
end)

DiscordClient:connectAsync()
