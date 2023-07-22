local DotEnv = require("../.env")
local DiscordLuaU = require("../Source/init")

local DiscordSettings = DiscordLuaU.DiscordSettings.new(DotEnv.DISCORD_BOT_TOKEN)

DiscordSettings:SetIntents(DiscordLuaU.DiscordIntents.all())

local DiscordClient = DiscordLuaU.DiscordClient.new(DiscordSettings)

-- DiscordClient:SetVerboseLogging(true)

DiscordClient:Subscribe("OnMessage", function(discordMessage)
	print(`User '{discordMessage.Author.GlobalName}': '{discordMessage.Content}'`)

	discordMessage:ReplyAsync("Testing! Whoo hoo!")
end)

DiscordClient:Subscribe("OnReady", function()
	print(`Aplication '{DiscordClient.User.Username}' is online!`)

	local discordPresence = DiscordLuaU.DiscordPresence.new()
	local discordActivity = DiscordLuaU.DiscordActivity.new()

	discordActivity:SetActivityName("I am Testing!")
	discordActivity:SetActivityType(DiscordLuaU.DiscordActivity.Type.Game)

	discordPresence:SetStatus(DiscordLuaU.DiscordPresence.Status.Online)
	discordPresence:AddActivity(discordActivity)

	DiscordClient:UpdatePresenceAsync(discordPresence):andThen(function()
		print(`Updated Application '{DiscordClient.User.Username}' discord status!`)
	end)
end)

DiscordClient:ConnectAsync():catch(print)
