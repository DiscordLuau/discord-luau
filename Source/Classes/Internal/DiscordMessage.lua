local Styleguide = require("../../Utils/Styleguide")

local DiscordEndpoints = require("../../Enums/DiscordEndpoints")

local Promise = require("../../Dependencies/Github/Promise")

local DiscordMessage = {}

DiscordMessage.Type = "DiscordMessage"

DiscordMessage.Internal = {}
DiscordMessage.Interface = {}
DiscordMessage.Prototype = {
	Internal = DiscordMessage.Internal,
}

function DiscordMessage.Prototype:ReplyAsync(messageStr)
	return Promise.new(function(resolve, reject)
		self.DiscordClient.Gateway:PostAsync(string.format(
			DiscordEndpoints.BotCreateMessage,
			self.ChannelId
		), {
			content = messageStr,
			message_reference = {
				message_id = self.Id,
				channel_id = self.ChannelId,
				guild_id = self.GuildId,
				fail_if_not_exists = false
			}
		}):andThen(function()
			resolve()
		end):catch(function(...)
			reject(...)
		end)
	end)
end

function DiscordMessage.Prototype:ToString()
	return `{DiscordMessage.Type}<{self.Id}>`
end

function DiscordMessage.Interface.from(discordClient, rawJsonData, discordAuthor)
	if discordClient:GetFromCache(rawJsonData.id) then
		return discordClient:GetFromCache(rawJsonData.id)
	end

	local objectData = Styleguide.new(rawJsonData):PascalCase()

	objectData.DiscordClient = discordClient
	objectData.Author = discordAuthor

	return discordClient:AddToCache(rawJsonData.id, setmetatable(objectData, {
		__index = DiscordMessage.Prototype,
		__type = DiscordMessage.Type,
		__tostring = function(object)
			return object:ToString()
		end,
	}))
end

return DiscordMessage.Interface
