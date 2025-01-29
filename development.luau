local env = require(".env")

local discordLuau = require("./packages/discord_luau/src")
local builders = require("./packages/builders/src")

local discordBot = discordLuau.Bot.new({
	token = env.DISCORD_BOT_TOKEN,
	intents = builders.intents.new({ "Guilds" }):build(),
})

-- discordBot:getGuildAsync(guildId)

discordBot.onMessage:listen(function() end)

discordBot.onAllShardsReady:listen(function()
	xpcall(function()
		local guild = discordBot:getGuildAsync("1273035219561091193"):await():unwrapOk()
		local threads = guild:getThreadsAsync():await():unwrapOk()
		local thread = threads[1]

		local result = thread:unpinMessageAsync("1333953461628436611"):await():unwrapOk()

		print("request sent:", result)
	end, function(e)
		print(e)
	end)
end)

discordBot:connectAsync():await()
