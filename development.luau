local botObject = require("@core/bot")

local messageBuilder = require("@builders/message/message")
local actionRowBuilder = require("@builders/message/components/actionRow")
local buttonBuilder = require("@builders/message/components/button")
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

	discordBot.onComponentInteraction:listen(function(interaction)
		-- warn(interaction)

		assert(interaction.data, `e`)

		interaction:messageAsync({
			content = `You pressed the {interaction.data.customId} button!`,
		})
	end)

	discordBot.onCommandInteraction:listen(function(interaction)
		local button = buttonBuilder
			.new({
				customId = "custom-id",
				label = "label",
				style = "Blurple",
			})
			:build()

		local buttonList = actionRowBuilder
			.new({
				components = {
					button,
				},
			})
			:build()

		local message = messageBuilder
			.new({
				content = "abc",
				components = {
					buttonList,
				},
			})
			:build()

		local response = interaction:messageAsync(message):expect(`Something bad happened..`)
	end)
end)

discordBot:connectAsync():after(function()
	print("Connected to Discord!")
end)
