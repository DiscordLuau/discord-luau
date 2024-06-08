local DiscordLuau = require("@DiscordLuau")
local Env = require("@Env")

local DiscordSettings = DiscordLuau.SettingsBuilder.new(Env.DISCORD_BOT_TOKEN)
local DiscordClient = DiscordLuau.DiscordClient.new(DiscordSettings)

-- DiscordClient:setVerbose(true)

DiscordClient.eventManager.onReady:connect(function()
	print(`🎉🎉 {DiscordClient.discordUser.username} is online! 🎉🎉`)

	DiscordClient:fetchChannelAsync("1246395956296155197"):after(function(textChannel)
		local e = textChannel :: DiscordLuau.GuildForumChannel

		e:deleteAsync():after(function()
			print("DELETED!")
		end)
	end)
end)

DiscordClient:connectAsync()
