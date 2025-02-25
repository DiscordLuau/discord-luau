local env = require(".env")

local discordLuau = require("./packages/discord_luau/src")
local builders = require("./packages/builders/src")

local discordBot = discordLuau.Bot.new({
	token = env.DISCORD_BOT_TOKEN,
	intents = builders.intents.new({ "Guilds", "GuildMessages" }):build(),
	reconnect = true,
	logLevel = "Info",
})

discordBot.onAllShardsReady:listen(function() end)

discordBot:connectAsync():await()
