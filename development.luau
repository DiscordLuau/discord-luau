local botObject = require("@core/bot")
local dateTime = require("@std-polyfills/datetime")

local intentsBuilder = require("@builders/intents")
local widgetSettings = require("@builders/guild/widgetSettings")

local env = require(".env")

local PENGU_BOT_ID = "726819179054891149"
local DISCORD_LUAU_GENERAL_ID = "1273035768700338278"
local DISCORD_LUAU_SERVER = "1273035219561091193"

local discordIntents = intentsBuilder.new()

discordIntents:addIntent("Guilds")

local discordBot = botObject.new({
	token = env.DISCORD_BOT_TOKEN,
	intents = discordIntents:build(),
})

discordBot.onAllShardsReady:listen(function()
	assert(discordBot.application, ``)

	local guild = discordBot:getGuildAsync(DISCORD_LUAU_SERVER):expect("1")
	local textChannel = discordBot:getTextChannelAsync(DISCORD_LUAU_GENERAL_ID):expect("2")

	textChannel:createMessageAsync({
		content = "Hello, world!",
	})
end)

discordBot:connectAsync():after(function()
	print("Connected to Discord!")
end)
