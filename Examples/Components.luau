local DiscordLuau = require("..")
local Env = require("../.env")

local DiscordSettings = DiscordLuau.SettingsBuilder.new(Env.DISCORD_BOT_TOKEN)
local DiscordClient = DiscordLuau.DiscordClient.new(DiscordSettings)

DiscordClient.eventManager.onReady:connect(function()
	print(`🎉🎉 {DiscordClient.discordUser.username} is online! 🎉🎉`)

	local discordChannel = DiscordClient:fetchChannelAsync("1048686561685946489"):await()

	discordChannel:sendMessageAsync(
		DiscordLuau.MessageBuilder.new():setContent("Hello, I have jus woken up!"):addComponent(
			DiscordLuau.ActionRowBuilder
				.new()
				:addComponent(
					DiscordLuau.ButtonBuilder
						.new("button-0")
						:setDisabled(true)
						:setStyle(DiscordLuau.ButtonBuilder.Style.Blurple)
						:setLabel("Burple")
				)
				:addComponent(
					DiscordLuau.ButtonBuilder
						.new("button-1")
						:setDisabled(true)
						:setStyle(DiscordLuau.ButtonBuilder.Style.Green)
						:setLabel("Green")
				)
				:addComponent(
					DiscordLuau.ButtonBuilder
						.new("button-2")
						:setDisabled(true)
						:setStyle(DiscordLuau.ButtonBuilder.Style.Grey)
						:setLabel("Grey")
				)
				:addComponent(
					DiscordLuau.ButtonBuilder
						.new("button-3")
						:setDisabled(true)
						:setStyle(DiscordLuau.ButtonBuilder.Style.Red)
						:setLabel("Red")
				)
		)
	)
end)

DiscordClient:connectAsync()
