local DiscordLuau = require("..")
local Env = require("../.env")

local DiscordSettings = DiscordLuau.SettingsBuilder.new(Env.DISCORD_BOT_TOKEN)
local DiscordClient = DiscordLuau.DiscordClient.new(DiscordSettings)

-- DiscordClient:setVerbose(true)

DiscordClient.eventManager.onReady:connect(function()
	print(`🎉🎉 {DiscordClient.discordUser.username} is online! 🎉🎉`)

	local textChannel = DiscordClient:fetchChannelAsync("1048686561685946489"):await()
	local responseMessage = DiscordLuau.MessageBuilder.new()

	responseMessage:addFile("Hello, World!", "e.txt")

	textChannel:sendMessageAsync(responseMessage)
end)

DiscordClient:connectAsync()
