local DiscordLuau = require("..")
local Env = require("../.env")

local DiscordSettings = DiscordLuau.SettingsBuilder.new(Env.DISCORD_BOT_TOKEN)
local DiscordClient = DiscordLuau.DiscordClient.new(DiscordSettings)

DiscordClient:setVerbose(true)

DiscordClient.eventManager.onReady:connect(function()
	print(`🎉🎉 {DiscordClient.discordUser.username} is online! 🎉🎉`)

	local permissions = DiscordLuau.PermissionsBuilder.new()

	permissions:addPermission(DiscordLuau.PermissionsBuilder.Permissions.SendMessages)

	local slashCommand = DiscordLuau.CommandBuilder
		.new()
		:setName("work-please")
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
