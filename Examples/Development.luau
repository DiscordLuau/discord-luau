local DiscordLuau = require("..")
local Env = require("../.env")

local Task = require("@lune/task")

local DiscordSettings = DiscordLuau.DiscordSettings.new(Env.DISCORD_BOT_TOKEN)
local DiscordClient = DiscordLuau.DiscordClient.new(DiscordSettings)

-- DiscordClient:setVerbose(true)

DiscordClient:on("Ready", function()
	print(`🎉🎉 {DiscordClient.discordUser.username} is online! 🎉🎉`)

	local voiceChannel = DiscordClient:fetchChannelAsync("1134076704495775844"):await()

	voiceChannel:connectAsync():after(function()
		Task.wait(5)

		print("disconnect!")
		voiceChannel:disconnectAsync()
	end)
end)

DiscordClient:connectAsync()