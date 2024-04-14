local DiscordIntents = require("DiscordIntents")

local Construct = require("../Utils/Construct")

local DiscordSettings = {}

DiscordSettings.Interface = {}
DiscordSettings.Prototype = { }

function DiscordSettings.Prototype.setDiscordToken(self: DiscordSettings, discordToken: string)
	self.DiscordToken = discordToken
end

function DiscordSettings.Prototype.setIntents(self: DiscordSettings, discordIntents: DiscordIntents.DiscordIntents)
	self.DiscordIntents = discordIntents
end

function DiscordSettings.Interface.new(discordToken: string, discordIntents: DiscordIntents.DiscordIntents?)
	return Construct({
		DiscordToken = discordToken,
		DiscordIntents = discordIntents or DiscordIntents.fromDefault(),
	}, DiscordSettings.Prototype)
end

export type DiscordSettings = typeof(DiscordSettings.Interface.new(""))

return DiscordSettings.Interface