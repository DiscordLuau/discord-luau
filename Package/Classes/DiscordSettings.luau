local DiscordIntents = require("DiscordIntents")

local Construct = require("../Utils/Construct")

--[=[
	@class DiscordSettings

	A simple class to retain some generic data before a Discord Client can be started, for inst;

	- The discord bot Token/Authentication
	- The discord bot Intents

	```lua
		local DiscordLuau = require("../Submodules/DiscordLuau")

		local DiscordIntents = DiscordLuau.DiscordIntents.fromAll()
		local DiscordSettings = DiscordLuau.DiscordSettings.new("BOT TOKEN", DiscordIntents)

		...
	```
]=]
local DiscordSettings = {}

DiscordSettings.Interface = {}
DiscordSettings.Prototype = {}

DiscordSettings.Prototype.type = "DiscordSettings"

function DiscordSettings.Prototype.setDiscordToken(self: DiscordSettings, discordToken: string)
	self.discordToken = discordToken
end

function DiscordSettings.Prototype.setIntents(self: DiscordSettings, discordIntents: DiscordIntents.DiscordIntents)
	self.discordIntents = discordIntents
end

function DiscordSettings.Interface.new(discordToken: string, discordIntents: DiscordIntents.DiscordIntents?)
	return Construct({
		discordToken = discordToken,
		discordIntents = discordIntents or DiscordIntents.fromDefault(),
	}, DiscordSettings.Prototype)
end

export type DiscordSettings = typeof(DiscordSettings.Interface.new(""))

return DiscordSettings.Interface