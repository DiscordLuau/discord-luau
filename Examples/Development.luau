local DiscordLuau = require("..")
local Env = require("../.env")

local DiscordSettings = DiscordLuau.SettingsBuilder.new(Env.DISCORD_BOT_TOKEN)
local DiscordClient = DiscordLuau.DiscordClient.new(DiscordSettings)

DiscordClient:setVerbose(true)

-- DiscordClient.eventManager.onMessage:connect(function(e)
-- 	e:replyAsync(DiscordLuau.MessageBuilder.new():setContent("e"))
-- end)

DiscordClient.eventManager.onReady:connect(function()
	print(`🎉🎉 {DiscordClient.discordUser.username} is online! 🎉🎉`)
end)

DiscordClient:connectAsync():after(function()
	local discordPresence = DiscordLuau.PresenceBuilder.new()
	local discordActivity = DiscordLuau.ActivityBuilder.new()

	discordActivity:setActivityName("AsyncMatrix program at 3AM")
	discordActivity:setActivityType(DiscordLuau.ActivityBuilder.Type.Watching)

	discordPresence:setStatus(DiscordLuau.PresenceBuilder.Status.Idle)
	discordPresence:addActivity(discordActivity)
	discordPresence:setSince(0)

	DiscordClient:updatePresenceAsync(discordPresence):after(function()
		print(`e`)
	end)
end)
