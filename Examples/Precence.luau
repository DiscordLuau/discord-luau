local DiscordLuau = require("..")
local Env = require("../.env")

local DiscordSettings = DiscordLuau.DiscordSettingsBuilder.new(Env.DISCORD_BOT_TOKEN)
local DiscordClient = DiscordLuau.DiscordClient.new(DiscordSettings)

DiscordClient.eventManager.onReady:connect(function()
	print(`🎉🎉 {DiscordClient.discordUser.username} is online! 🎉🎉`)

	local discordPresence = DiscordLuau.DiscordPresenceBuilder.new()
	local discordActivity = DiscordLuau.DiscordActivityBuilder.new()

	discordActivity:setActivityName("AsyncMatrix program at 3AM")
	discordActivity:setActivityType(DiscordLuau.DiscordActivityBuilder.Type.Watching)

	discordPresence:setStatus(DiscordLuau.DiscordPresenceBuilder.Status.Idle)
	discordPresence:addActivity(discordActivity)
	discordPresence:setSince(0)

	DiscordClient:updatePresenceAsync(discordPresence):after(function()
		print(`Updated '{DiscordClient.discordUser.username}' preasence!`)
	end)
end)

DiscordClient:connectAsync()