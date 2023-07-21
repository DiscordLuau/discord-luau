local DiscordIntents = require("DiscordIntents")

local DiscordSettings = {}

DiscordSettings.Type = "DiscordSettings"

DiscordSettings.Internal = {}
DiscordSettings.Interface = {}
DiscordSettings.Prototype = {
	Internal = DiscordSettings.Internal,
}

function DiscordSettings.Prototype:SetDiscordToken(discordToken)
	self.DiscordToken = discordToken
end

function DiscordSettings.Prototype:SetIntents(discordIntents)
	self.DiscordIntents = discordIntents
end

function DiscordSettings.Prototype:ToString()
	local safeDiscordToken = self.DiscordToken

	safeDiscordToken = string.sub(safeDiscordToken, 1, 40)
	safeDiscordToken ..= ` ...`

	return `{DiscordSettings.Type}<"{safeDiscordToken}">`
end

function DiscordSettings.Interface.new(discordToken)
	return setmetatable({
		DiscordToken = discordToken,
		DiscordIntents = DiscordIntents.default()
	}, {
		__index = DiscordSettings.Prototype,
		__type = DiscordSettings.Type,
		__tostring = function(self)
			return self:ToString()
		end,
	})
end

return DiscordSettings.Interface
