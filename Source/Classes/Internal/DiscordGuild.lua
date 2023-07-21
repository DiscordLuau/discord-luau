local Styleguide = require("../../Utils/Styleguide")

local DiscordGuild = {}

DiscordGuild.Type = "DiscordGuild"

DiscordGuild.Internal = {}
DiscordGuild.Interface = {}
DiscordGuild.Prototype = {
	Internal = DiscordGuild.Internal,
}

function DiscordGuild.Prototype:ToString()
	return `{DiscordGuild.Type}<{self.Id}>`
end

function DiscordGuild.Interface.from(discordClient, rawJsonData)
	if discordClient:GetFromCache(rawJsonData.id) then
		return discordClient:GetFromCache(rawJsonData.id)
	end

	local objectData = Styleguide.new(rawJsonData):PascalCase()

	objectData.DiscordClient = discordClient

	return discordClient:AddToCache(rawJsonData.id, setmetatable(objectData, {
		__index = DiscordGuild.Prototype,
		__type = DiscordGuild.Type,
		__tostring = function(object)
			return object:ToString()
		end,
	}))
end

return DiscordGuild.Interface
