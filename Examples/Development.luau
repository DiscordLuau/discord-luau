local DiscordLuau = require("..")
local Env = require("../.env")

local MESSAGE_DELETION_SIZE = 5

local DiscordSettings = DiscordLuau.DiscordSettings.new(Env.DISCORD_BOT_TOKEN)
local DiscordClient = DiscordLuau.DiscordClient.new(DiscordSettings)

DiscordClient:setVerbose(true)

DiscordClient:on("Ready", function()
	print(`🎉🎉 {DiscordClient.discordUser.username} is online! 🎉🎉`)

	local channelObject = DiscordClient:fetchChannelAsync("1048686561685946489"):await()

	print(channelObject:getInvitesAsync():await())
end)

DiscordClient:connectAsync()