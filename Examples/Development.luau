local DiscordLuau = require("..")
local Env = require("../.env")

local DiscordSettings = DiscordLuau.SettingsBuilder.new(Env.DISCORD_BOT_TOKEN)
local DiscordClient = DiscordLuau.DiscordClient.new(DiscordSettings)

DiscordClient:setVerbose(true)

DiscordClient.eventManager.onInteraction:connect(function(e)
	local responseMessage = DiscordLuau.MessageBuilder
		.new()
		:addFile(
			DiscordLuau.AttachmentBuilder
				.new()
				:setName("Example.txt")
				:setData("Hello, World, STYLUA STOP CHANGING MY BUILDER FORMAT!")
		)
		:setContent("e")

	e:sendMessageAsync(responseMessage)
end)

DiscordClient:connectAsync()
