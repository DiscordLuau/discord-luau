local DiscordLuau = require("..")
local Env = require("../.env")

local DiscordSettings = DiscordLuau.DiscordSettings.new(Env.DISCORD_BOT_TOKEN)
local DiscordClient = DiscordLuau.DiscordClient.new(DiscordSettings)

DiscordClient:on("Ready", function()
	print(`🎉🎉 {DiscordClient.discordUser.username} is online! 🎉🎉`)

	local discordPresence = DiscordLuau.DiscordPresence.new()
	local discordActivity = DiscordLuau.DiscordActivity.new()

	discordActivity:setActivityName("AsyncMatrix program at 3AM")
	discordActivity:setActivityType(DiscordLuau.DiscordActivity.Type.Watching)

	discordPresence:setStatus(DiscordLuau.DiscordPresence.Status.Idle)
	discordPresence:addActivity(discordActivity)
	discordPresence:setSince(0)

	DiscordClient:updatePresenceAsync(discordPresence):after(function()
		print(`Updated '{DiscordClient.discordUser.username}' preasence!`)
	end)
end)

DiscordClient:connectAsync()