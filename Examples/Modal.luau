local Task = require("@lune/task")

local DiscordLuau = require("..")
local Env = require("../.env")

local DiscordSettings = DiscordLuau.DiscordSettings.new(Env.DISCORD_BOT_TOKEN)
local DiscordClient = DiscordLuau.DiscordClient.new(DiscordSettings)

DiscordClient:on("Interaction", function(interaction: DiscordLuau.DiscordInteraction)
	if interaction.data.name == "example-command" then
		local discordModal = DiscordLuau.DiscordModal.new("response-modal")

		discordModal:setTitle("Modal Test")

		discordModal:addComponent(
			DiscordLuau.Components.ActionRowComponent.new()
				:addComponent(
					DiscordLuau.Components.TextInputComponent.new("text-input-0")
						:setLabel("Label #0")
						:setMaxLength(1000)
						:setMinLength(10)
						:setRequired(true)
						:setStyle(DiscordLuau.Components.TextInputComponent.Style.Paragraph)
				)
		)

		interaction:sendModalAsync(discordModal)
	else
		interaction:deferAsync():await()

		Task.delay(1, function()
			interaction:sendMessageAsync({
				content = "Feedback noted, thanks!",
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
	end
end)

DiscordClient:on("Ready", function()
	print(`🎉🎉 {DiscordClient.discordUser.username} is online! 🎉🎉`)

	local permissions = DiscordLuau.DiscordPermissions.new()

	permissions:addPermission(DiscordLuau.DiscordPermissions.SendMessages)

	local slashCommand = DiscordLuau.ApplicationCommand.new()
		:setName("example-command")
		:setDescription("Example Description")
		:SetGuildPermissions(permissions)

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