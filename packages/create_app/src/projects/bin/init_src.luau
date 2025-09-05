return function()
	return [[local discord = require("@self/../luau_packages/discord")
local classes = require("@self/../luau_packages/classes")
local builders = require("@self/../luau_packages/builders")

local env = require("@self/../.env")

local DISCORD_BOT_INTENTS = builders.intents
	.new({
		"Guilds",
		"GuildMessages",
		"MessageContent",
	})
	:build()

local bot = discord.bot.new({
	token = env.DISCORD_BOT_TOKEN,
	intents = DISCORD_BOT_INTENTS,
	reconnect = true,
	logLevel = "Debug",
})

bot.onMessage:listen(function(message: classes.Message)
	print(`Message sent by '{message.author.globalName}' said: '{message.content}'`)
end)

bot.onAllShardsReady:listenOnce(function()
	print(`Bot '{bot.application.name}' is online!`)
end)

bot:connectAsync():await()
]]
end
