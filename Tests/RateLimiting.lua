local DotEnv = require("../.env")
local DiscordLuaU = require("../Source/init")

local DiscordSettings = DiscordLuaU.DiscordSettings.new(DotEnv.DISCORD_BOT_TOKEN)

DiscordSettings:SetIntents(DiscordLuaU.DiscordIntents.all())

local DiscordClient = DiscordLuaU.DiscordClient.new(DiscordSettings)

DiscordClient:SetVerboseLogging(true)

DiscordClient:Subscribe("OnReady", function()
	DiscordClient:GetChannelAsync("1048686561685946489"):andThen(function(discordChannel)
		for index = 1, 10 do
			discordChannel:SendMessageAsync(`Hello, {index}!`):andThen(function()
				print(`Sent {index} message!`)
			end):catch(function(exception)
				print(`Failed to send {index} message: {exception}`)
			end)
		end
	end)
end)

DiscordClient:ConnectAsync():catch(print)
