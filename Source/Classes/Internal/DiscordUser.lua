local Styleguide = require("../../Utils/Styleguide")

local DiscordUser = {}

DiscordUser.Type = "DiscordUser"

DiscordUser.Internal = {}
DiscordUser.Interface = {}
DiscordUser.Prototype = {
	Internal = DiscordUser.Internal,
}

function DiscordUser.Prototype:ToString()
	return `{DiscordUser.Type}<{self.Id}>`
end

function DiscordUser.Interface.from(discordClient, rawJsonData)
	if discordClient:GetFromCache(rawJsonData.id) then
		return discordClient:GetFromCache(rawJsonData.id)
	end

	local objectData = Styleguide.new(rawJsonData):PascalCase()

	objectData.DiscordClient = discordClient

	return discordClient:AddToCache(rawJsonData.id, setmetatable(objectData, {
		__index = DiscordUser.Prototype,
		__type = DiscordUser.Type,
		__tostring = function(object)
			return object:ToString()
		end,
	}))
end

return DiscordUser.Interface
