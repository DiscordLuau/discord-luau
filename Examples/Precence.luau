local DiscordLuau = require("@DiscordLuau")
local Env = require("@Env")

local DiscordSettings = DiscordLuau.SettingsBuilder.new(Env.DISCORD_BOT_TOKEN)
local DiscordClient = DiscordLuau.DiscordClient.new(DiscordSettings)

DiscordClient.eventManager.onReady:connect(function()
	print(`🎉🎉 {DiscordClient.discordUser.username} is online! 🎉🎉`)

	local discordPresence = DiscordLuau.PresenceBuilder.new()
	local discordActivity = DiscordLuau.ActivityBuilder.new()

	discordActivity:setActivityName("AsyncMatrix program at 3AM")
	discordActivity:setActivityType(DiscordLuau.ActivityBuilder.Type.Watching)

	discordPresence:setStatus(DiscordLuau.PresenceBuilder.Status.Idle)
	discordPresence:addActivity(discordActivity)
	discordPresence:setSince(0)

	DiscordClient:updatePresenceAsync(discordPresence):after(function()
		print(`Updated '{DiscordClient.discordUser.username}' preasence!`)
	end)
end)

DiscordClient:connectAsync()
