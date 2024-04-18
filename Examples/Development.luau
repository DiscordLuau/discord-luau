local DiscordLuau = require("..")
local Env = require("../.env")

local DiscordSettings = DiscordLuau.DiscordSettings.new(Env.DISCORD_BOT_TOKEN)
local DiscordClient = DiscordLuau.DiscordClient.new(DiscordSettings)

DiscordClient:on("Message", function(message: DiscordLuau.DiscordMessage)
	print(`DiscordUser '{message.author.username}' has said; {message.content}`)

	if string.find(string.lower(message.content), "hello") then
		if message.author.id == DiscordClient.discordUser.id then
			return
		end

		message:replyAsync({
			content = "Hello, from Discord-Luau!"
		})
	end
end)

DiscordClient:on("Ready", function()
	print(`🎉🎉 {DiscordClient.discordUser.username} is online! 🎉🎉`)

	local discordChannel = DiscordClient:fetchChannelAsync("1048686561685946489"):await()

	discordChannel:sendMessageAsync({
		content = "Hello, World! I sent this through the Discord Channel API!"
	})

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

	-- local discordGuild = DiscordClient:fetchGuildAsync("737382889947136000"):await()
	-- local discordGuildCommands = discordGuild:fetchSlashCommandsAsync():await()

	-- for _, discordCommand in discordGuildCommands do
	-- 	discordGuild:deleteSlashCommandAsync(discordCommand.id):after(function()
	-- 		print("deleted guild command; ", discordCommand.id)
	-- 	end)
	-- end
end)

DiscordClient:connectAsync()