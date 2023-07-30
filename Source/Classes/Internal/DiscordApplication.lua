local Promise = require("../../Dependencies/Github/Promise")

local DiscordEndpoints = require("../../Enums/DiscordEndpoints")

local Styleguide = require("../../Utils/Styleguide")

local DiscordApplication = {}

DiscordApplication.Type = "DiscordApplication"

DiscordApplication.Internal = {}
DiscordApplication.Interface = {}
DiscordApplication.Prototype = {
	Internal = DiscordApplication.Internal,
}

function DiscordApplication.Prototype:GetAllGlobalCommandsAsync()
	return Promise.new(function(resolve, reject)
		self.DiscordClient.Gateway:GetAsync(string.format(
			DiscordEndpoints.GetGlobalApplicationCommands,
			self.Id
		)):andThen(function(...)
			resolve(...)
		end):catch(function(...)
			reject(...)
		end)
	end)
end

function DiscordApplication.Prototype:CreateGlobalCommandAsync(commandObject)
	return Promise.new(function(resolve, reject)
		self.DiscordClient.Gateway:PostAsync(string.format(
			DiscordEndpoints.CreateGlobalApplicationCommand,
			self.Id
		), commandObject:ToJSONObject()):andThen(function()
			resolve()
		end):catch(function(...)
			reject(...)
		end)
	end)
end

function DiscordApplication.Prototype:GetGlobalCommandAsync(commandId)
	return Promise.new(function(resolve, reject)
		self.DiscordClient.Gateway:GetAsync(string.format(
			DiscordEndpoints.GetGlobalApplicationCommand,
			self.Id, commandId
		)):andThen(function()
			resolve()
		end):catch(function(...)
			reject(...)
		end)
	end)
end

function DiscordApplication.Prototype:DeleteGlobalCommandAsync(commandId)
	return Promise.new(function(resolve, reject)
		self.DiscordClient.Gateway:DeleteAsync(string.format(
			DiscordEndpoints.DeleteGlobalApplicationCommand,
			self.Id, commandId
		)):andThen(function()
			resolve()
		end):catch(function(...)
			reject(...)
		end)
	end)
end

function DiscordApplication.Prototype:GetAllGuildCommandsAsync(guildId)
	return Promise.new(function(resolve, reject)
		self.DiscordClient.Gateway:GetAsync(string.format(
			DiscordEndpoints.GetGuildApplicationCommands,
			self.Id, guildId
		)):andThen(function()
			resolve()
		end):catch(function(...)
			reject(...)
		end)
	end)
end

function DiscordApplication.Prototype:CreateGuildCommandAsync(guildId, commandObject)
	return Promise.new(function(resolve, reject)
		self.DiscordClient.Gateway:PostAsync(string.format(
			DiscordEndpoints.GetGuildApplicationCommands,
			self.Id, guildId
		), commandObject:ToJSONObject()):andThen(function()
			resolve()
		end):catch(function(...)
			reject(...)
		end)
	end)
end

function DiscordApplication.Prototype:GetGuildCommandAsync(guildId, commandId)
	return Promise.new(function(resolve, reject)
		self.DiscordClient.Gateway:GetAsync(string.format(
			DiscordEndpoints.GetGuildApplicationCommands,
			self.Id, guildId, commandId
		)):andThen(function()
			resolve()
		end):catch(function(...)
			reject(...)
		end)
	end)
end

function DiscordApplication.Prototype:DeleteGuildCommandAsync(guildId, commandId)
	return Promise.new(function(resolve, reject)
		self.DiscordClient.Gateway:DeleteAsync(string.format(
			DiscordEndpoints.GetGuildApplicationCommands,
			self.Id, guildId, commandId
		)):andThen(function()
			resolve()
		end):catch(function(...)
			reject(...)
		end)
	end)
end

function DiscordApplication.Prototype:ToString()
	return `{DiscordApplication.Type}<{self.Id}>`
end

function DiscordApplication.Interface.from(discordClient, rawJsonData)
	if discordClient:GetFromCache(`APPLICATION_{rawJsonData.id}`) then
		return discordClient:GetFromCache(`APPLICATION_{rawJsonData.id}`)
	end

	local objectData = Styleguide.new(rawJsonData):PascalCase()

	objectData.DiscordClient = discordClient

	return discordClient:AddToCache(`APPLICATION_{rawJsonData.id}`, setmetatable(objectData, {
		__index = DiscordApplication.Prototype,
		__type = DiscordApplication.Type,
		__tostring = function(object)
			return object:ToString()
		end,
	}))
end

return DiscordApplication.Interface
