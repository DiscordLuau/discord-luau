local DiscordLuau = require("..")
local Env = require("../.env")

local DiscordSettings = DiscordLuau.SettingsBuilder.new(Env.DISCORD_BOT_TOKEN)
local DiscordClient = DiscordLuau.DiscordClient.new(DiscordSettings)

DiscordClient:setVerbose(true)

DiscordClient.eventManager.onReady:connect(function()
	print(`🎉🎉 {DiscordClient.discordUser.username} is online! 🎉🎉`)

	local channel = DiscordClient:fetchDMChannelAsync("685566749516628033"):await() :: DiscordLuau.UserDMChannel

	channel:sendMessageAsync(DiscordLuau.MessageBuilder.new():setContent("hello!"))
end)

return DiscordClient:connectAsync()
