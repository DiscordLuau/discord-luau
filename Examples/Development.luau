local DiscordLuau = require("..")
local Env = require("../.env")

local DiscordSettings = DiscordLuau.DiscordSettings.new(Env.DISCORD_BOT_TOKEN)
local DiscordClient = DiscordLuau.DiscordClient.new(DiscordSettings)

DiscordClient:setVerbose(true)

DiscordClient:on("Ready", function()
	print(`🎉🎉 {DiscordClient.discordUser.username} is online! 🎉🎉`)

	local channelObject = DiscordClient:fetchChannelAsync("1048686561685946489"):await()

	channelObject:sendMessageAsync({
		embeds = {
			DiscordLuau.DiscordEmbed.new()
				:setTitle("Hello, World!")
				:setColor(0xFF0000)
				:setDescription("A test embed object!")
		}
	})
end)

DiscordClient:connectAsync()