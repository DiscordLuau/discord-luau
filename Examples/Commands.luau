local DiscordLuau = require("..")
local Env = require("../.env")

local DiscordSettings = DiscordLuau.DiscordSettingsBuilder.new(Env.DISCORD_BOT_TOKEN)
local DiscordClient = DiscordLuau.DiscordClient.new(DiscordSettings)

DiscordClient:setVerbose(true)

DiscordClient.eventManager.onReady:connect(function()
	print(`🎉🎉 {DiscordClient.discordUser.username} is online! 🎉🎉`)

	local permissions = DiscordLuau.DiscordPermissionsBuilder.new()

	permissions:addPermission(DiscordLuau.DiscordPermissionsBuilder.Permissions.UseApplicationCommands)

	local slashCommand0 = DiscordLuau.ApplicationCommandBuilder.new()
		:setName("example-0")
		:setDescription("...")
		:setGuildPermissions(permissions)
		:addContext(DiscordLuau.ApplicationCommandBuilder.Context.Guild)
		:setType(DiscordLuau.ApplicationCommandBuilder.Type.ChatInput)

	local slashCommand1 = DiscordLuau.ApplicationCommandBuilder.new()
		:setName("example-1")
		:setDescription("abc!")
		:setGuildPermissions(permissions)
		:addContext(DiscordLuau.ApplicationCommandBuilder.Context.Guild)
		:setType(DiscordLuau.ApplicationCommandBuilder.Type.ChatInput)

	DiscordClient.discordApplication:setSlashCommandsAsync({
		slashCommand0, slashCommand1
	}):after(function(data)
		print("updated, fetching current commands..")
		DiscordClient.discordApplication:fetchSlashCommandsAsync():after(function(...)
			print(...)
		end)
	end)
end)

DiscordClient:connectAsync()