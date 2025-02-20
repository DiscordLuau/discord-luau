local task = require("@lune/task")

local env = require(".env")

local discordLuau = require("./packages/discord_luau/src")
local builders = require("./packages/builders/src")

local discordBot = discordLuau.Bot.new({
	token = env.DISCORD_BOT_TOKEN,
	intents = builders.intents.new({ "Guilds" }):build(),
	reconnect = true,
})

discordBot.onMessage:listen(function() end)

discordBot.onAllShardsReady:listen(function()
	local channel = discordBot:getTextChannelAsync("1273035768700338278"):await():unwrapOk()

	for id, shard in discordBot.state.webSocketManager.shards do
		shard.onSocketDisconnected:listen(function(_, e)
			if e then
				return
			end

			channel
				:createMessageAsync({
					content = `Shard '{id}' DOWN!`,
				})
				:poll()
		end)

		shard.onSocketConnected:listen(function()
			channel
				:createMessageAsync({
					content = `Shard '{id}' UP!`,
				})
				:poll()
		end)

		task.wait(5)

		channel
			:createMessageAsync({
				content = `Shard '{id}' DOWN! (manual invoke)`,
			})
			:poll()

		shard:reconnectAsync():poll()
	end
end)

discordBot:connectAsync():await()
