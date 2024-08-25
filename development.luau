local DiscordLuau = require("@core/init")

local discordBot = DiscordLuau.Bot.new({
	token = "",
	intents = 0,
})

discordBot:connectAsync():after(function()
	print("Connected to Discord!")
end)
