local task = require("@lune/task")

local env = require(".env")

local discordLuau = require("./packages/discord_luau/src")
local builders = require("./packages/builders/src")

local discordBot = discordLuau.Bot.new({
	token = env.DISCORD_BOT_TOKEN,
	intents = builders.intents.new({ "Guilds", "GuildMessages" }):build(),
	reconnect = true,
	logLevel = "Info",
})

discordBot.onAllShardsReady:listen(function()
	local channel = discordBot:getTextChannelAsync("1344070759722647654"):await():unwrapOk()

	local index = 0

	while true do
		index += 1
		local response = channel
			:createMessageAsync({
				content = `Example: '{index}'`,
			})
			:await()

		if not response:isOk() then
			print(response)
		end

		task.wait(1)
	end
end)

discordBot:connectAsync():await()
