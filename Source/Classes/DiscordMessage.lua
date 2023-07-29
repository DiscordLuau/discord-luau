local Styleguide = require("../Utils/Styleguide")

local DiscordEndpoints = require("../Enums/DiscordEndpoints")

local Promise = require("../Dependencies/Github/Promise")

local DiscordMember = require("Internal/DiscordMember")
local DiscordUser = require("Internal/DiscordUser")

local DiscordMessage = {}

DiscordMessage.Type = "DiscordMessage"

DiscordMessage.Internal = {}
DiscordMessage.Interface = {}
DiscordMessage.Prototype = {
	Internal = DiscordMessage.Internal,
}

function DiscordMessage.Prototype:ReplyAsync(discordMessage)
	local messageJson = discordMessage:ToJSONObject()

	messageJson.message_reference = {
		message_id = self.Id,
		channel_id = self.ChannelId,
		guild_id = self.GuildId,
		fail_if_not_exists = false
	}

	return Promise.new(function(resolve, reject)
		self.DiscordClient.Gateway:PostAsync(string.format(
			DiscordEndpoints.BotCreateMessage,
			self.ChannelId
		), messageJson):andThen(function()
			resolve()
		end):catch(function(...)
			reject(...)
		end)
	end)
end

function DiscordMessage.Prototype:AddEmbed(embedObject)
	table.insert(self.Embeds, embedObject)

	return self
end

function DiscordMessage.Prototype:RemoveEmbed(embedObject)
	local index = table.find(self.Embeds, embedObject)

	if index then
		table.remove(self.Embeds, index)
	end

	return self
end

function DiscordMessage.Prototype:AddComponent(componentObject)
	table.insert(self.Components, componentObject)

	return self
end

function DiscordMessage.Prototype:RemoveComponent(componentObject)
	local index = table.find(self.Components, componentObject)

	if index then
		table.remove(self.Components, index)
	end

	return self
end

function DiscordMessage.Prototype:ToJSONObject()
	local discordEmbeds = {}
	local discordComponents = {}

	for index, discordEmbed in self.Embeds do
		discordEmbeds[index] = discordEmbed:ToJSONObject()
	end

	for index, discordComponent in self.Components do
		discordComponents[index] = discordComponent:ToJSONObject()
	end

	return {
		content = self.Content,
		embeds = discordEmbeds,
		components = discordComponents
	}
end

function DiscordMessage.Prototype:ToString()
	return `{DiscordMessage.Type}<{self.Id}>`
end

function DiscordMessage.Interface.from(discordClient, rawJsonData)
	if discordClient:GetFromCache(`MESSAGE_{rawJsonData.id}`) then
		return discordClient:GetFromCache(`MESSAGE_{rawJsonData.id}`)
	end

	local objectData = Styleguide.new(rawJsonData):PascalCase()

	objectData.DiscordClient = discordClient
	objectData.Author = DiscordUser.from(discordClient, rawJsonData.author)

	rawJsonData.member.user_id = rawJsonData.author.id
	objectData.Member = DiscordMember.from(discordClient, rawJsonData.member, rawJsonData.guild_id)

	return discordClient:AddToCache(`MESSAGE_{rawJsonData.id}`, setmetatable(objectData, {
		__index = DiscordMessage.Prototype,
		__type = DiscordMessage.Type,
		__tostring = function(object)
			return object:ToString()
		end,
	}))
end

function DiscordMessage.Interface.new(messageContent)
	return setmetatable({
		Content = messageContent,
		Embeds = { },
		Components = { }
	}, {
		__index = DiscordMessage.Prototype,
		__type = DiscordMessage.Type,
		__tostring = function(object)
			return object:ToString()
		end,
	})
end

return DiscordMessage.Interface
