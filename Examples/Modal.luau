local Task = require("@Std/Task")

local DiscordLuau = require("@DiscordLuau")
local Env = require("@Env")

local DiscordSettings = DiscordLuau.SettingsBuilder.new(Env.DISCORD_BOT_TOKEN)
local DiscordClient = DiscordLuau.DiscordClient.new(DiscordSettings)

DiscordClient.eventManager.onInteraction:connect(function(interaction)
	if interaction.data.name == "example-command" then
		local discordModal = DiscordLuau.ModalBuilder.new("response-modal")

		discordModal:setTitle("Modal Test")

		discordModal:addComponent(
			DiscordLuau.ActionRowBuilder.new():addComponent(
				DiscordLuau.TextInputBuilder
					.new("text-input-0")
					:setLabel("Label #0")
					:setMaxLength(1000)
					:setMinLength(10)
					:setRequired(true)
					:setStyle(DiscordLuau.TextInputBuilder.Style.Paragraph)
			)
		)

		interaction:sendModalAsync(discordModal)
	else
		interaction:deferAsync():await()

		Task.delay(1, function()
			interaction:sendMessageAsync(
				DiscordLuau.MessageBuilder.new():setContent("Feedback noted, thanks!"):addComponent(
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
	end
end)

DiscordClient.eventManager.onReady:connect(function()
	print(`🎉🎉 {DiscordClient.discordUser.username} is online! 🎉🎉`)

	local permissions = DiscordLuau.PermissionsBuilder.new()

	permissions:addPermission(DiscordLuau.PermissionsBuilder.Permissions.SendMessages)

	local slashCommand = DiscordLuau.CommandBuilder
		.new()
		:setName("example-command")
		:setDescription("Example Description")
		:setGuildPermissions(permissions)
		:addContext(DiscordLuau.CommandBuilder.Context.Guild)
		:addIntegration(DiscordLuau.CommandBuilder.IntegrationType.GuildCommand)

	DiscordClient.discordApplication
		:setSlashCommandsAsync({
			slashCommand,
		})
		:after(function(data)
			print("updated, fetching current commands..")

			DiscordClient.discordApplication:fetchSlashCommandsAsync():after(function(...)
				print(...)
			end)
		end)
end)

DiscordClient:connectAsync()
