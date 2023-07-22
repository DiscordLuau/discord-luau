# Discord-Luau
A Luau discord API wrapper.

## Documentation
At the moment, there is no documentation for Discord-Luau, this being because this is a hobby project i'm doing in my free time.

Ideally, moving forward the plan is to use 'Moonwave' to generate API documentation.

## Example

```lua
local DiscordLuaU = require("../Source/init")

local DiscordSettings = DiscordLuaU.DiscordSettings.new("DiscordBotToken")

DiscordSettings:SetIntents(DiscordLuaU.DiscordIntents.all())

local DiscordClient = DiscordLuaU.DiscordClient.new(DiscordSettings)

-- DiscordClient:SetVerboseLogging(true)

DiscordClient:Subscribe("OnMessage", function(discordMessage)
	print(`User '{discordMessage.Author.GlobalName}': '{discordMessage.Content}'`)

	discordMessage:ReplyAsync("Testing! Whoo hoo!")
end)

DiscordClient:Subscribe("OnReady", function()
	print(`Aplication '{DiscordClient.User.Username}' is online!`)

	local discordPresence = DiscordLuaU.DiscordPresence.new()
	local discordActivity = DiscordLuaU.DiscordActivity.new()

	discordActivity:SetActivityName("I am Testing!")
	discordActivity:SetActivityType(DiscordLuaU.DiscordActivity.Type.Game)

	discordPresence:SetStatus(DiscordLuaU.DiscordPresence.Status.Online)
	discordPresence:AddActivity(discordActivity)

	DiscordClient:UpdatePresenceAsync(discordPresence):andThen(function()
		print(`Updated Application '{DiscordClient.User.Username}' discord status!`)
	end)
end)

DiscordClient:ConnectAsync():catch(print)
```
