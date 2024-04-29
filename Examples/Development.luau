local DiscordLuau = require("..")
local Env = require("../.env")

local MESSAGE_DELETION_SIZE = 5

local DiscordSettings = DiscordLuau.DiscordSettings.new(Env.DISCORD_BOT_TOKEN)
local DiscordClient = DiscordLuau.DiscordClient.new(DiscordSettings)

DiscordClient:setVerbose(true)

DiscordClient:on("Ready", function()
	print(`🎉🎉 {DiscordClient.discordUser.username} is online! 🎉🎉`)

	local textChannel = DiscordClient:fetchChannelAsync("1048686561685946489"):await()

	textChannel:getMessagesAsync(MESSAGE_DELETION_SIZE):after(function(messageQueue)
		for _, message in messageQueue do
			message:replyAsync({
				content = message.content
			})
		end
	end)
end)

DiscordClient:connectAsync()