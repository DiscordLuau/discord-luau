local task = require("@lune/task")

local env = require(".env")

local discordLuau = require("./packages/discord_luau/src")
local builders = require("./packages/builders/src")

local discordBot = discordLuau.Bot.new({
	token = env.DISCORD_BOT_TOKEN,
	intents = builders.intents.new({ "Guilds" }):build(),
})

discordBot.onMessage:listen(function() end)

discordBot.onAllShardsReady:listen(function()
	local i = 0

	task.wait(2)

	while true do
		i += 1

		print("sent")
		discordBot
			:setPresenceAsync({
				afk = true,
				since = 0,
				status = "idle",
				activities = {
					{
						type = 0,
						name = `Idling out at '{i}'`,
					},
				},
			})
			:await()

		task.wait(0.5)
	end
end)

discordBot:connectAsync():await()
