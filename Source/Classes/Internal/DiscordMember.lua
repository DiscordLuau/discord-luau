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

function DiscordMember.Interface.from(discordClient, rawJsonData, discordMessage)
	if discordClient:GetFromCache(`{discordMessage.Author.Id}_{discordMessage.GuildId}`) then
		return discordClient:GetFromCache(`{discordMessage.Author.Id}_{discordMessage.GuildId}`)
	end

	local objectData = Styleguide.new(rawJsonData):PascalCase()

	objectData.DiscordClient = discordClient

	return discordClient:AddToCache(`{discordMessage.Author.Id}_{discordMessage.GuildId}`, setmetatable(objectData, {
		__index = DiscordMember.Prototype,
		__type = DiscordMember.Type,
		__tostring = function(object)
			return object:ToString()
		end,
	}))
end

return DiscordMember.Interface
