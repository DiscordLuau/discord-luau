local Styleguide = require("../../Utils/Styleguide")

local DiscordMember = {}

DiscordMember.Type = "DiscordMember"

DiscordMember.Internal = {}
DiscordMember.Interface = {}
DiscordMember.Prototype = {
	Internal = DiscordMember.Internal,
}

function DiscordMember.Prototype:ToString()
	return `{DiscordMember.Type}<{self.Id}>`
end

function DiscordMember.Interface.from(discordClient, rawJsonData, guildId)
	if discordClient:GetFromCache(`MEMBER_{rawJsonData.user_id}_{guildId}`) then
		return discordClient:GetFromCache(`MEMBER_{rawJsonData.user_id}_{guildId}`)
	end

	local objectData = Styleguide.new(rawJsonData):PascalCase()

	objectData.DiscordClient = discordClient

	return discordClient:AddToCache(`MEMBER_{rawJsonData.user_id}_{guildId}`, setmetatable(objectData, {
		__index = DiscordMember.Prototype,
		__type = DiscordMember.Type,
		__tostring = function(object)
			return object:ToString()
		end,
	}))
end

return DiscordMember.Interface
