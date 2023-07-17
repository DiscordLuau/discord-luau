local DiscordLuaU = require("../Source/init")

local Task = require("@lune/task")

local DISCORD_BOT_TOKEN = "NzI2ODE5MTc5MDU0ODkxMTQ5.GlmKcT.s2AK7wJQPAVjplkqhb0JKfxPALkschibCGLpkQ"

local DiscordClient = DiscordLuaU.DiscordClient.new({
	token = DISCORD_BOT_TOKEN,
	intents = DiscordLuaU.DiscordIntents.default(),
})

-- DiscordClient:Subscribe("OnMessage", function(discordUser, discordMessage)
-- 	print(discordUser, discordMessage)
-- end)

DiscordClient:Subscribe("OnReady", function()
	local discordPresence = DiscordLuaU.DiscordPresence.new()

	print(`Bot '{DiscordClient.Username}#{DiscordClient.Discriminator}' is online!`)

	Task.spawn(function()
		while true do
			discordPresence:SetStatus(DiscordLuaU.DiscordPresence.Status.Online)

			DiscordClient:UpdatePresenceAsync(discordPresence):andThen(function()
				print(
					`Bot '{DiscordClient.Username}#{DiscordClient.Discriminator}' set status to: {discordPresence.Status}`
				)
			end)

			Task.wait(20)

			discordPresence:SetStatus(DiscordLuaU.DiscordPresence.Status.Idle)

			DiscordClient:UpdatePresenceAsync(discordPresence):andThen(function()
				print(
					`Bot '{DiscordClient.Username}#{DiscordClient.Discriminator}' set status to: {discordPresence.Status}`
				)
			end)

			Task.wait(20)
		end
	end)
end)

DiscordClient:ConnectAsync():catch(print)
