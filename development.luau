local env = require(".env")

local discordLuau = require("packages/discord_luau/src")
local builders = require("packages/builders/src")

local discordBot = discordLuau.Bot.new({
	token = env.DISCORD_BOT_TOKEN,
	intents = builders.intents.new({ "Guild" }):build(),
})

discordBot.onAllShardsReady:listen(function()
	print("we're up and running!")
end)

discordBot:connectAsync():after(function()
	print("Connected to Discord!")
end)
