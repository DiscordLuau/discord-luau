local DiscordLuau = require("..")
local Env = require("../.env")

local DiscordSettings = DiscordLuau.DiscordSettings.new(Env.DISCORD_BOT_TOKEN)
local DiscordClient = DiscordLuau.DiscordClient.new(DiscordSettings)

DiscordClient:setVerbose(true)

DiscordClient:on("Ready", function()
	print(`🎉🎉 {DiscordClient.discordUser.username} is online! 🎉🎉`)

	local permissions = DiscordLuau.DiscordPermissions.new()

	permissions:addPermission(DiscordLuau.DiscordPermissions.Permissions.UseApplicationCommands)

	local slashCommand0 = DiscordLuau.ApplicationCommand.new()
		:setName("example-0")
		:setDescription("...")
		:setGuildPermissions(permissions)
		:addContext(DiscordLuau.ApplicationCommand.Context.Guild)
		:setType(DiscordLuau.ApplicationCommand.Type.ChatInput)

	local slashCommand1 = DiscordLuau.ApplicationCommand.new()
		:setName("example-1")
		:setDescription("abc!")
		:setGuildPermissions(permissions)
		:addContext(DiscordLuau.ApplicationCommand.Context.Guild)
		:setType(DiscordLuau.ApplicationCommand.Type.ChatInput)

	DiscordClient.discordApplication:setSlashCommandsAsync({
		slashCommand0, slashCommand1
	}):after(function(data)
		print("updated, fetching current commands..")
		-- DiscordClient.discordApplication:fetchSlashCommandsAsync():after(function(...)
		-- 	print(...)
		-- end)
	end)
end)

DiscordClient:connectAsync()