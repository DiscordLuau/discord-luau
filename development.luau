local Bot = require("@core/bot")
local IntentsBuilder = require("@builders/intentsBuilder")

local env = require(".env")

local discordBot = Bot.new({
	token = env.DISCORD_BOT_TOKEN,
	intents = IntentsBuilder.new():addIntent("Guilds"):build(),
})

discordBot.onReady:listen(function(shardId)
	print(`Shard {shardId} is ready!`)
end)

discordBot.onInteraction:listen(function(a) end)

discordBot:connectAsync():after(function()
	print("Connected to Discord!")
end)
