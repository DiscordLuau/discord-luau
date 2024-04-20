local DiscordLuau = require("..")
local Env = require("../.env")

local DiscordSettings = DiscordLuau.DiscordSettings.new(Env.DISCORD_BOT_TOKEN)
local DiscordClient = DiscordLuau.DiscordClient.new(DiscordSettings)

DiscordClient:on("Message", function(message: DiscordLuau.DiscordMessage)
	print(`DiscordUser '{message.author.username}' has said; {message.content}`)

	if string.find(string.lower(message.content), "hello") then
		if message.author.id == DiscordClient.discordUser.id then
			return
		end

		message:replyAsync({
			content = "Hello, from Discord-Luau!"
		})
	end
end)

DiscordClient:on("Ready", function()
	print(`🎉🎉 {DiscordClient.discordUser.username} is online! 🎉🎉`)
end)

DiscordClient:connectAsync()