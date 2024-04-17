local DiscordLuau = require("..")
local Env = require("../.env")

local DiscordSettings = DiscordLuau.DiscordSettings.new(Env.DISCORD_BOT_TOKEN)
local DiscordClient = DiscordLuau.DiscordClient.new(DiscordSettings)

DiscordClient:on("Ready", function()
	print(`🎉🎉 {DiscordClient.discordUser.username} is online! 🎉🎉`)

	-- local slashCommand = DiscordLuau.ApplicationCommand.new()
	-- 	:setName("example-command")
	-- 	:setDescription("Example Description")

	-- DiscordClient.discordApplication:setSlashCommandsAsync({
	-- 	slashCommand
	-- }):after(function(data)
	-- 	print("updated, fetching current commands..")
	-- 	DiscordClient.discordApplication:fetchSlashCommandsAsync():after(function(...)
	-- 		print(...)
	-- 	end)
	-- end)

	local discordGuild = DiscordClient:fetchGuildAsync("737382889947136000"):await()
	local discordGuildCommands = discordGuild:fetchSlashCommandsAsync():await()

	for _, discordCommand in discordGuildCommands do
		discordGuild:deleteSlashCommandAsync(discordCommand.id):after(function()
			print("deleted guild command; ", discordCommand.id)
		end)
	end
end)

DiscordClient:connectAsync()