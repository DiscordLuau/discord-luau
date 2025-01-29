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
		local channel = discordBot:getForumChannelAsync("1334296315038929009"):await():unwrapOk()

		local result = channel
			:createPostAsync({
				message = {
					content = "hi guys",
				},
				name = "test post",
			})
			:await()

		print("request sent:", result)
	end, function(e)
		print(e)
	end)
end)

discordBot:connectAsync():await()
