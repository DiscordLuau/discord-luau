local Bot = require("@core/bot")
local IntentsBuilder = require("@builders/intentsBuilder")

local env = require(".env")

local discordBot = Bot.new({
	token = env.DISCORD_BOT_TOKEN,
	intents = IntentsBuilder.new()
		:addIntent("GuildMessages")
		:addIntent("GuildMembers")
		:addIntent("MessageContent")
		:build(),
})

discordBot.onReady:listen(function(shardId)
	print(`Shard {shardId} is ready!`)
end)

discordBot.onMessage:listen(function(message)
	if not message.flags then
		return
	end

	print(`MESSAGE CREATED:`, message.content)
	print(`MESSAGE HAS THREAD:`, message.flags:hasThread())
end)

discordBot:connectAsync():after(function()
	print("Connected to Discord!")
end)
