local env = require(".env")

local discordLuau = require("./packages/discord_luau/src")
local builders = require("./packages/builders/src")

local discordBot = discordLuau.Bot.new({
	token = env.DISCORD_BOT_TOKEN,
	intents = builders.intents.new({ "Guilds", "GuildMessages" }):build(),
	reconnect = true,
	logLevel = "Info",
})

discordBot.onModalInteraction:listen(function(interaction)
	local content = interaction:getContent("example-input")

	interaction
		:messageAsync({
			content = `Thanks! Input received: '{content}'`,
		})
		:await()
end)

discordBot.onCommandInteraction:listen(function(interaction)
	interaction
		:modalAsync({
			title = "abc",
			custom_id = "modal",
			components = {
				{
					type = 1,
					components = {
						{
							type = 4,
							custom_id = "example-input",
							style = 1,
							label = "Message",
						},
					},
				},
			},
		}, true)
		:await()
end)

discordBot.onAllShardsReady:listen(function() end)

discordBot:connectAsync():await()
