local DotEnv = require("../.env")
local DiscordLuaU = require("../Source/init")

local DiscordSettings = DiscordLuaU.DiscordSettings.new(DotEnv.DISCORD_BOT_TOKEN)

DiscordSettings:SetIntents(DiscordLuaU.DiscordIntents.all())

local DiscordClient = DiscordLuaU.DiscordClient.new(DiscordSettings)

DiscordClient:SetVerboseLogging(true)

DiscordClient:Subscribe("OnReady", function()
	local discordEmbed = DiscordLuaU.DiscordEmbed.new()
		:SetTitle("Testing 101")
		:SetDescription("My Awesome Description!")

	DiscordClient:GetChannelAsync("1048686561685946489"):andThen(function(discordChannel)
		local discordMessage = DiscordLuaU.DiscordMessage.new("Hello, World!")

		discordMessage:AddEmbed(discordEmbed)
		discordChannel:SendMessageAsync(discordMessage):andThen(function()
			print(`Sent message!`)
		end):catch(function(exception)
			print(`Failed to send message: {exception}`)
		end)
	end)
end)

DiscordClient:ConnectAsync():catch(print)
