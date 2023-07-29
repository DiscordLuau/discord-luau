local Task = require("@lune/task")
local Serde = require("@lune/serde")

local DotEnv = require("../.env")
local DiscordLuaU = require("../Source/init")

local DiscordSettings = DiscordLuaU.DiscordSettings.new(DotEnv.DISCORD_BOT_TOKEN)

DiscordSettings:SetIntents(DiscordLuaU.DiscordIntents.all())

local DiscordClient = DiscordLuaU.DiscordClient.new(DiscordSettings)

-- DiscordClient:SetVerboseLogging(true)

DiscordClient:Subscribe("OnInteraction", function(interactionObject)
	interactionObject:DeferAsync()

	Task.delay(interactionObject.Data.Options[1].Value, function()
		local discordMessage = DiscordLuaU.DiscordMessage.new(interactionObject.Data.Options[2].Value)

		interactionObject:SendMessageAsync(discordMessage)
	end)
end)

DiscordClient:Subscribe("OnReady", function()
	local timeOption = DiscordLuaU.ApplicationCommandOptions.new()
		:SetType(DiscordLuaU.ApplicationCommandOptions.Type.Integer)
		:SetName("time")
		:SetDescription("Time to wait until responding.")
		:SetMinValue(1)
		:SetMaxValue(60)
		:SetRequired(true)

	local stringOption = DiscordLuaU.ApplicationCommandOptions.new()
		:SetType(DiscordLuaU.ApplicationCommandOptions.Type.String)
		:SetName("message")
		:SetDescription("The message to respond with.")
		:SetMinLength(1)
		:SetMaxLength(300)
		:SetRequired(true)

	local applicationCommand = DiscordLuaU.ApplicationCommand.new()
		:SetType(DiscordLuaU.ApplicationCommand.Type.ChatInput)
		:SetName("say-message-in")
		:SetDescription("Send a message in X seconds!")
		:AddOption(timeOption)
		:AddOption(stringOption)

	DiscordClient.Application:CreateGlobalCommandAsync(applicationCommand):andThen(function()
		print("Discord Command Added!")
	end)
end)

DiscordClient:ConnectAsync():catch(print)
