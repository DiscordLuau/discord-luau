local DiscordLuaU = require("../Source/init")

local DISCORD_BOT_TOKEN = "NzI2ODE5MTc5MDU0ODkxMTQ5.G65VEW.--------------------------------------"

local DiscordClient = DiscordLuaU.DiscordClient.new({
	token = DISCORD_BOT_TOKEN,
	intents = DiscordLuaU.DiscordIntents.default(),
})

-- DiscordClient:Subscribe("OnMessage", function(discordUser, discordMessage)
-- 	print(discordUser, discordMessage)
-- end)

DiscordClient:Subscribe("OnReady", function()
	print(`Bot '{DiscordClient.Username}#{DiscordClient.Discriminator}' is online!`)

	local discordPresence = DiscordLuaU.DiscordPresence.new()
	local discordActivity = DiscordLuaU.DiscordActivity.new()

	discordActivity:SetActivityName("I am Testing!")
	discordActivity:SetActivityType(DiscordLuaU.DiscordActivity.Type.Game)

	discordPresence:SetStatus(DiscordLuaU.DiscordPresence.Status.Online)
	discordPresence:AddActivity(discordActivity)

	DiscordClient:UpdatePresenceAsync(discordPresence):andThen(function()
		print(
			`Updated '{DiscordClient.Username}#{DiscordClient.Discriminator}' activity!`
		)
	end)
end)

DiscordClient:ConnectAsync():catch(print)
