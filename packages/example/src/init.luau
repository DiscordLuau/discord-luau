local discordLuau = require("@self/../luau_packages/discord")
local discordBuilders = require("@self/../luau_packages/builders")

local env = require("@self/../../../.env")

local discordBot = discordLuau.bot.new({
	token = env.DISCORD_BOT_TOKEN,
	intents = discordBuilders.intents.new({ "Guilds", "GuildMessages" }):build(),
	reconnect = true,
	logLevel = "Info",
})

discordBot.onAllShardsReady:listenOnce(function()
	print("We up!")
end)

discordBot:connectAsync():poll()
