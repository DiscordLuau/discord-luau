local DiscordEndpoints = require("../../Enums/DiscordEndpoints")

local Promise = require("../../Dependencies/Github/Promise")

local Styleguide = require("../../Utils/Styleguide")

local DiscordChannel = {}

DiscordChannel.Type = "DiscordChannel"

DiscordChannel.Internal = {}
DiscordChannel.Interface = {}
DiscordChannel.Prototype = {
	Internal = DiscordChannel.Internal,
}

function DiscordChannel.Prototype:SendMessageAsync(discordMessage)
	return Promise.new(function(resolve, reject)
		self.DiscordClient.Gateway:PostAsync(string.format(
			DiscordEndpoints.BotCreateMessage,
			self.Id
		), discordMessage:ToJSONObject()):andThen(function()
			resolve()
		end):catch(function(...)
			reject(...)
		end)
	end)
end

function DiscordChannel.Prototype:ToString()
	return `{DiscordChannel.Type}<{self.Id}>`
end

function DiscordChannel.Interface.from(discordClient, rawJsonData)
	if discordClient:GetFromCache(rawJsonData.id) then
		return discordClient:GetFromCache(rawJsonData.id)
	end

	local objectData = Styleguide.new(rawJsonData):PascalCase()

	objectData.DiscordClient = discordClient

	return discordClient:AddToCache(rawJsonData.id, setmetatable(objectData, {
		__index = DiscordChannel.Prototype,
		__type = DiscordChannel.Type,
		__tostring = function(object)
			return object:ToString()
		end,
	}))
end

function DiscordChannel.Interface.fetchAsync(discordClient, id)
	return Promise.new(function(resolve, reject)
		if discordClient:GetFromCache(id) then
			return resolve(discordClient:GetFromCache(id))
		end

		discordClient.Gateway:GetAsync(string.format(DiscordEndpoints.BotGetChannel, id)):andThen(function(rawJsonData)
			resolve(DiscordChannel.Interface.from(discordClient, rawJsonData))
		end):catch(function(exception)
			reject(exception)
		end)
	end)
end

return DiscordChannel.Interface
