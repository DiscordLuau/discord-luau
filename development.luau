local task = require("@lune/task")

local env = require(".env")

local discordLuau = require("./packages/discord_luau/src")
local classes = require("./packages/classes/src")
local builders = require("./packages/builders/src")

local discordBot = discordLuau.Bot.new({
	token = env.DISCORD_BOT_TOKEN,
	intents = builders.intents.new({ "Guilds" }):build(),
	reconnect = true,
	logLevel = "Info",
})

discordBot.onMessage:listen(function() end)

discordBot.onAllShardsReady:listen(function() end)

discordBot:connectAsync():await()
