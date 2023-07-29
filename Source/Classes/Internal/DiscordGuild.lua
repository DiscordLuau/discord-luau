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
	if discordClient:GetFromCache(`GUILD_{rawJsonData.id}`) then
		return discordClient:GetFromCache(`GUILD_{rawJsonData.id}`)
	end

	local objectData = Styleguide.new(rawJsonData):PascalCase()

	objectData.DiscordClient = discordClient

	return discordClient:AddToCache(`GUILD_{rawJsonData.id}`, setmetatable(objectData, {
		__index = DiscordGuild.Prototype,
		__type = DiscordGuild.Type,
		__tostring = function(object)
			return object:ToString()
		end,
	}))
end

return DiscordGuild.Interface
