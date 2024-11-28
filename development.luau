local env = require(".env")

local discordLuau = require("packages/core/src")
local builders = require("packages/builders/src")

local discordBot = discordLuau.Bot.new({
	intents = builders.intents.new({ "Guilds" }):build(),
	token = env.DISCORD_BOT_TOKEN,
})

discordBot.onAllShardsReady:listen(function()
	assert(discordBot.application, ``)

	print("we're up and running!")
end)

discordBot:connectAsync():after(function()
	print("Connected to Discord!")
end)
