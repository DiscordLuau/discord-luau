local DiscordLuau = require("@DiscordLuau")
local Env = require("@Env")

local DiscordSettings = DiscordLuau.SettingsBuilder.new(Env.DISCORD_BOT_TOKEN)
local DiscordClient = DiscordLuau.DiscordClient.new(DiscordSettings)

-- DiscordClient:setVerbose(true)

DiscordClient.eventManager.onReady:connect(function()
	print(`🎉🎉 {DiscordClient.discordUser.username} is online! 🎉🎉`)

	local textChannel = DiscordClient:fetchChannelAsync("1048686561685946489"):await() :: DiscordLuau.GuildTextChannel
	local responseMessage = DiscordLuau.MessageBuilder.new()

	responseMessage:addFile(
		DiscordLuau.AttachmentBuilder
			.new()
			:setData("Hello, World")
			:setDescription("Example File")
			:setName("Example.txt")
	)

	textChannel:sendMessageAsync(responseMessage)
end)

DiscordClient:connectAsync()
