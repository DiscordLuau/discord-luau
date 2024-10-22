local botObject = require("@core/bot")

local messageBuilder = require("@builders/message/message")
local intentsBuilder = require("@builders/intents")
local interactionBuilder = require("@builders/interaction/interaction")

local env = require(".env")

local discordIntents = intentsBuilder.new()

discordIntents:addIntent("Guilds")

local discordBot = botObject.new({
	token = env.DISCORD_BOT_TOKEN,
	intents = discordIntents:build(),
})

discordBot.onAllShardsReady:listen(function()
	assert(discordBot.application, ``)

	local interaction = interactionBuilder
		.new()
		:setName(`interaction-name`)
		:setDescription("An example interaction, created with the rewrite of Discord-Luau!")
		:addContext("Guild")
		:addContext("BotDm")
		:addContext("PrivateChannel")
		:addIntegrationType("GuildInstall")
		:addIntegrationType("UserInstall")

	print(`Creating slash command...`)
	discordBot.application:createSlashCommandAsync(interaction:build()):after(function(command)
		print(`Created slash command:`, command)
	end)

	discordBot.onPingInteraction:listen(function(interaction)
		interaction:pongAsync()
	end)

	discordBot.onCommandInteraction:listen(function(interaction)
		local message = interaction
			:messageAsync({
				content = "abc",
			}, true)
			:expect(`Something bad happened..`)

		print(message)
	end)
end)

discordBot:connectAsync():after(function()
	print("Connected to Discord!")
end)
