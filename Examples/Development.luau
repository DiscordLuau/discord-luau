local DiscordLuau = require("..")
local Env = require("../.env")

local MESSAGE_DELETION_SIZE = 5

local DiscordSettings = DiscordLuau.DiscordSettings.new(Env.DISCORD_BOT_TOKEN)
local DiscordClient = DiscordLuau.DiscordClient.new(DiscordSettings)

DiscordClient:setVerbose(true)

DiscordClient:on("Ready", function()
	print(`🎉🎉 {DiscordClient.discordUser.username} is online! 🎉🎉`)

	local guildObject = DiscordClient:fetchGuildAsync("737382889947136000"):await()

	print(guildObject:getGuildAuditLogs():await())
end)

DiscordClient:connectAsync()