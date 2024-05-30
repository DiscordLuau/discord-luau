local DiscordLuau = require("..")
local Env = require("../.env")

local DiscordSettings = DiscordLuau.SettingsBuilder.new(Env.DISCORD_BOT_TOKEN)
local DiscordClient = DiscordLuau.DiscordClient.new(DiscordSettings)

DiscordClient:setVerbose(true)

DiscordClient.eventManager.onReady:connect(function()
	print(`🎉🎉 {DiscordClient.discordUser.username} is online! 🎉🎉`)

	local permissions = DiscordLuau.PermissionsBuilder.new()

	permissions:addPermission(DiscordLuau.PermissionsBuilder.Permissions.UseApplicationCommands)

	local slashCommand0 = DiscordLuau.CommandBuilder
		.new()
		:setName("example-0")
		:setDescription("...")
		:setGuildPermissions(permissions)
		:addContext(DiscordLuau.CommandBuilder.Context.Guild)
		:addIntegration(DiscordLuau.CommandBuilder.IntegrationType.GuildCommand)

	local slashCommand1 = DiscordLuau.CommandBuilder
		.new()
		:setName("example-1")
		:setDescription("abc!")
		:setGuildPermissions(permissions)
		:addContext(DiscordLuau.CommandBuilder.Context.Guild)
		:addIntegration(DiscordLuau.CommandBuilder.IntegrationType.GuildCommand)

	DiscordClient.discordApplication
		:setSlashCommandsAsync({
			slashCommand0,
			slashCommand1,
		})
		:after(function(data)
			print("updated, fetching current commands..")
			DiscordClient.discordApplication:fetchSlashCommandsAsync():after(function(...)
				print(...)
			end)
		end)
end)

DiscordClient:connectAsync()
