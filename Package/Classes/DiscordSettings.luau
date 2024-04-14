local DiscordIntents = require("DiscordIntents")

local Construct = require("../Utils/Construct")

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