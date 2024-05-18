local DiscordLuau = require("..")
local Env = require("../.env")

local DiscordSettings = DiscordLuau.DiscordSettings.new(Env.DISCORD_BOT_TOKEN)
local DiscordClient = DiscordLuau.DiscordClient.new(DiscordSettings)

DiscordClient.eventManager.onReady:connect(function()
	print(`🎉🎉 {DiscordClient.discordUser.username} is online! 🎉🎉`)

	local discordChannel = DiscordClient:fetchChannelAsync("1048686561685946489"):await()

	discordChannel:sendMessageAsync({
		content = "Hello, I have jus woken up!",
		components = {
			DiscordLuau.Components.ActionRowComponent.new()
				:addComponent(
					DiscordLuau.Components.ButtonComponent.new("button-0")
						:setDisabled(true)
						:setStyle(DiscordLuau.Components.ButtonComponent.Style.Blurple)
						:setLabel("Burple")
				)
				:addComponent(
					DiscordLuau.Components.ButtonComponent.new("button-1")
						:setDisabled(true)
						:setStyle(DiscordLuau.Components.ButtonComponent.Style.Green)
						:setLabel("Green")
				)
				:addComponent(
					DiscordLuau.Components.ButtonComponent.new("button-2")
						:setDisabled(true)
						:setStyle(DiscordLuau.Components.ButtonComponent.Style.Grey)
						:setLabel("Grey")
				)
				:addComponent(
					DiscordLuau.Components.ButtonComponent.new("button-3")
						:setDisabled(true)
						:setStyle(DiscordLuau.Components.ButtonComponent.Style.Red)
						:setLabel("Red")
				)
		}
	})
end)

DiscordClient:connectAsync()