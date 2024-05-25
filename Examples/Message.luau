local DiscordLuau = require("..")
local Env = require("../.env")

local DiscordSettings = DiscordLuau.SettingsBuilder.new(Env.DISCORD_BOT_TOKEN)
local DiscordClient = DiscordLuau.DiscordClient.new(DiscordSettings)

DiscordClient.eventManager.onMessage:connect(function(message)
	print(`DiscordUser '{message.author.username}' has said; {message.content}`)

	if string.find(string.lower(message.content), "hello") then
		if message.author.id == DiscordClient.discordUser.id then
			return
		end

		message:replyAsync(
		DiscordLuau.MessageBuilder.new()
				:setContent(`Hello, from Discord-Luau!`)
		)
	end
end)

DiscordClient.eventManager.onReady:connect(function()
	print(`🎉🎉 {DiscordClient.discordUser.username} is online! 🎉🎉`)
end)

DiscordClient:connectAsync()