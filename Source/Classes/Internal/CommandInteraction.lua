local Styleguide = require("../../Utils/Styleguide")

local DiscordEndpoints = require("../../Enums/DiscordEndpoints")

local Promise = require("../../Dependencies/Github/Promise")

local DiscordChannel = require("DiscordChannel")
local DiscordMember = require("DiscordMember")
local DiscordUser = require("DiscordUser")
local DiscordGuild = require("DiscordGuild")

local CommandInteraction = {}

CommandInteraction.Type = "CommandInteraction"

CommandInteraction.Internal = {}
CommandInteraction.Interface = {}
CommandInteraction.Prototype = {
	Internal = CommandInteraction.Internal,
}

function CommandInteraction.Prototype:EditMessageAsync(discordMessage)
	local messageJson = discordMessage:ToJSONObject()

	return Promise.new(function(resolve, reject)
		self.DiscordClient.Gateway:PatchAsync(string.format(
			DiscordEndpoints.EditOriginalInteractionResponse,
			self.DiscordClient.Application.Id,
			self.Token
		), messageJson):andThen(function()
			resolve()
		end):catch(function(...)
			reject(...)
		end)
	end)
end

function CommandInteraction.Prototype:SendModalAsync(modalObject)
	return Promise.new(function(resolve, reject)
		self.DiscordClient.Gateway:PostAsync(string.format(
			DiscordEndpoints.CreateInteractionResponse,
			self.Id,
			self.Token
		), {
			type = 9,
			data = modalObject:ToJSONObject()
		}):andThen(function()
			resolve()
		end):catch(function(...)
			reject(...)
		end)
	end)
end

function CommandInteraction.Prototype:SendMessageAsync(discordMessage)
	local messageJson = discordMessage:ToJSONObject()

	if self.Deferred then
		return self:EditMessageAsync(discordMessage)
	else
		return Promise.new(function(resolve, reject)
			self.DiscordClient.Gateway:PostAsync(string.format(
				DiscordEndpoints.CreateInteractionResponse,
				self.Id,
				self.Token
			), {
				type = 4,
				data = messageJson
			}):andThen(function()
				resolve()
			end):catch(function(...)
				reject(...)
			end)
		end)
	end
end

function CommandInteraction.Prototype:DeferAsync()
	return Promise.new(function(resolve, reject)
		self.DiscordClient.Gateway:PostAsync(string.format(
			DiscordEndpoints.CreateInteractionResponse,
			self.Id,
			self.Token
		), {
			type = 5,
			data = { }
		}):andThen(function()
			self.Deferred = true

			resolve()
		end):catch(function(...)
			reject(...)
		end)
	end)
end

function CommandInteraction.Prototype:ToString()
	return `{CommandInteraction.Type}<{self.Id}>`
end

function CommandInteraction.Interface.from(discordClient, rawJsonData)
	local objectData = Styleguide.new(rawJsonData):PascalCase()

	objectData.DiscordClient = discordClient

	objectData.Channel = DiscordChannel.from(discordClient, rawJsonData.channel)
	objectData.Guild = DiscordGuild.from(discordClient, rawJsonData.guild)
	objectData.User = DiscordUser.from(discordClient, rawJsonData.member.user)

	rawJsonData.member.user_id = rawJsonData.member.user.id
	objectData.Member = DiscordMember.from(discordClient, rawJsonData.member, rawJsonData.guild.id)

	return setmetatable(objectData, {
		__index = CommandInteraction.Prototype,
		__type = CommandInteraction.Type,
		__tostring = function(object)
			return object:ToString()
		end,
	})
end

return CommandInteraction.Interface
