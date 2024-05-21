local DiscordLuau = require("..")
local Env = require("../.env")

local DiscordSettings = DiscordLuau.DiscordSettingsBuilder.new(Env.DISCORD_BOT_TOKEN)
local DiscordClient = DiscordLuau.DiscordClient.new(DiscordSettings)

DiscordClient:setVerbose(true)

DiscordClient.eventManager.onMessage:connect(function(message)
	message:replyAsync(
		DiscordLuau.DiscordMessageBuilder.new()
			:setContent(`Hello, {message.author.username}`)
	)
end)

DiscordClient.eventManager.onReady:connect(function()
	print(`🎉🎉 {DiscordClient.discordUser.username} is online! 🎉🎉`)
end)

DiscordClient:connectAsync()