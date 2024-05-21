local Task = require("@lune/task")

local DiscordLuau = require("..")
local Env = require("../.env")

local DiscordSettings = DiscordLuau.DiscordSettingsBuilder.new(Env.DISCORD_BOT_TOKEN)
local DiscordClient = DiscordLuau.DiscordClient.new(DiscordSettings)

DiscordClient.eventManager.onInteraction:connect(function(interaction)
	if interaction.data.name == "example-command" then
		local discordModal = DiscordLuau.DiscordModalBuilder.new("response-modal")

		discordModal:setTitle("Modal Test")

		discordModal:addComponent(
			DiscordLuau.Components.ActionRowBuilder.new()
				:addComponent(
					DiscordLuau.Components.TextInputBuilder.new("text-input-0")
						:setLabel("Label #0")
						:setMaxLength(1000)
						:setMinLength(10)
						:setRequired(true)
						:setStyle(DiscordLuau.Components.TextInputBuilder.Style.Paragraph)
				)
		)

		interaction:sendModalAsync(discordModal)
	else
		interaction:deferAsync():await()

		Task.delay(1, function()
			interaction:sendMessageAsync(
				DiscordLuau.DiscordMessageBuilder.new()
				:setContent("Feedback noted, thanks!")
				:addComponent(
					DiscordLuau.Components.ActionRowBuilder.new()
						:addComponent(
							DiscordLuau.Components.ButtonBuilder.new("button-0")
								:setDisabled(true)
								:setStyle(DiscordLuau.Components.ButtonBuilder.Style.Blurple)
								:setLabel("Burple")
						)
						:addComponent(
							DiscordLuau.Components.ButtonBuilder.new("button-1")
								:setDisabled(true)
								:setStyle(DiscordLuau.Components.ButtonBuilder.Style.Green)
								:setLabel("Green")
						)
						:addComponent(
							DiscordLuau.Components.ButtonBuilder.new("button-2")
								:setDisabled(true)
								:setStyle(DiscordLuau.Components.ButtonBuilder.Style.Grey)
								:setLabel("Grey")
						)
						:addComponent(
							DiscordLuau.Components.ButtonBuilder.new("button-3")
								:setDisabled(true)
								:setStyle(DiscordLuau.Components.ButtonBuilder.Style.Red)
								:setLabel("Red")
						)
				)
			)
		end)
	end
end)

DiscordClient.eventManager.onReady:connect(function()
	print(`🎉🎉 {DiscordClient.discordUser.username} is online! 🎉🎉`)

	local permissions = DiscordLuau.DiscordPermissionsBuilder.new()

	permissions:addPermission(DiscordLuau.DiscordPermissionsBuilder.Permissions.SendMessages)

	local slashCommand = DiscordLuau.ApplicationCommandBuilder.new()
		:setName("example-command")
		:setDescription("Example Description")
		:setGuildPermissions(permissions)

	DiscordClient.discordApplication:setSlashCommandsAsync({
		slashCommand
	}):after(function(data)
		print("updated, fetching current commands..")

		DiscordClient.discordApplication:fetchSlashCommandsAsync():after(function(...)
			print(...)
		end)
	end)
end)

DiscordClient:connectAsync()