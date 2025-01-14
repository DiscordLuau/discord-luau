local env = require(".env")

local discordLuau = require("packages/discord_luau/src")
local builders = require("packages/builders/src")

local discordBot = discordLuau.Bot.new({
	token = env.DISCORD_BOT_TOKEN,
	intents = builders.intents.new({ "Guilds" }):build(),
})

-- discordBot:getGuildAsync(guildId)

discordBot.onAllShardsReady:listen(function()
	print("we're up and running!")
end)

print(`Connecting to Discord...`)
discordBot
	:connectAsync()
	:after(function()
		print("Connected to Discord!")
	end)
	:poll()
