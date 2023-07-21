local Styleguide = require("../../Utils/Styleguide")

local DiscordApplication = {}

DiscordApplication.Type = "DiscordApplication"

DiscordApplication.Internal = {}
DiscordApplication.Interface = {}
DiscordApplication.Prototype = {
	Internal = DiscordApplication.Internal,
}

function DiscordApplication.Prototype:ToString()
	return `{DiscordApplication.Type}<{self.Id}>`
end

function DiscordApplication.Interface.from(discordClient, rawJsonData)
	if discordClient:GetFromCache(rawJsonData.id) then
		return discordClient:GetFromCache(rawJsonData.id)
	end

	local objectData = Styleguide.new(rawJsonData):PascalCase()

	objectData.DiscordClient = discordClient

	return discordClient:AddToCache(rawJsonData.id, setmetatable(objectData, {
		__index = DiscordApplication.Prototype,
		__type = DiscordApplication.Type,
		__tostring = function(object)
			return object:ToString()
		end,
	}))
end

return DiscordApplication.Interface
