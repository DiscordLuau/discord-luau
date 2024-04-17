local Construct = require("../../Utils/Construct")

local CacheType = require("../../Enums/CacheType")
local DiscordEndpoints = require("../../Enums/DiscordEndpoints")

local ApplicationCommand = require("../ApplicationCommand")

local DiscordEmoji = require("DiscordEmoji")
local DiscordGuildRole = require("DiscordGuildRole")

local Future = require("../../Vendor/Future")

--[=[
	@class Internal.DiscordGuild

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local DiscordGuild = {}

DiscordGuild.Prototype = {}
DiscordGuild.Interface = {}

DiscordGuild.Prototype.type = "DiscordGuild"

function DiscordGuild.Prototype.createSlashCommandAsync(self: DiscordGuild, command: ApplicationCommand.ApplicationCommand)
	return Future.try(function()
		return self.discordClient.discordGateway:postAsync(
			string.format(DiscordEndpoints.CreateGuildApplicationCommand, self.discordClient.discordApplication.id, self.id),
			command:toJSONObject()
		):await()
	end)
end

function DiscordGuild.Prototype.deleteSlashCommandAsync(self: DiscordGuild, commandId: string)
	return Future.try(function()
		return self.discordClient.discordGateway:deleteAsync(
			string.format(DiscordEndpoints.DeleteGuildApplicationCommand, self.discordClient.discordApplication.id, self.id, commandId)
		):await()
	end)
end

function DiscordGuild.Prototype.editSlashCommandAsync(self: DiscordGuild, commandId: string, command: ApplicationCommand.ApplicationCommand)
	return Future.try(function()
		return self.discordClient.discordGateway:patchAsync(
			string.format(DiscordEndpoints.EditGuildApplicationCommand, self.discordClient.discordApplication.id, self.id, commandId),
			command:toJSONObject()
		):await()
	end)
end

function DiscordGuild.Prototype.fetchSlashCommandsAsync(self: DiscordGuild)
	return Future.try(function()
		return self.discordClient.discordGateway:getAsync(
			string.format(DiscordEndpoints.GetGuildApplicationCommands, self.discordClient.discordApplication.id, self.id)
		):await()
	end)
end

function DiscordGuild.Prototype.setSlashCommandsAsync(self: DiscordGuild, commands: { ApplicationCommand.ApplicationCommand })
	return Future.try(function()
		local allCommands = self:fetchSlashCommandsAsync():await()

		local commandsToUpdate = {}
		local commandsToCreate = {}
		local commandsToDestroy = {}

		for _, commandObject0 in allCommands do
			local commandFoundInCommandsArray
			local commandReference

			for _, commandObject1 in commands do
				if commandObject0.name ~= commandObject1.name then
					continue
				end

				commandReference = commandObject1
				commandFoundInCommandsArray = true
				
				break
			end

			if commandFoundInCommandsArray then
				commandsToUpdate[commandReference.id] = commandObject0
			else
				table.insert(commandsToDestroy, commandObject0)
			end
		end

		for _, commandObject0 in commands do
			local commandFoundInUpdateCommandsArray

			for _, commandObject1 in commandsToUpdate do
				if commandObject0.name ~= commandObject1.name then
					continue
				end

				commandFoundInUpdateCommandsArray = true

				break
			end

			if not commandFoundInUpdateCommandsArray then
				table.insert(commandsToCreate, commandObject0)
			end
		end

		for _, commandStruct in commandsToDestroy do
			self:deleteSlashCommandAsync(commandStruct.id):await()
		end

		for commandId: string, command: ApplicationCommand.ApplicationCommand in commandsToUpdate do
			self:editSlashCommandAsync(commandId, command):await()
		end

		for _, command: ApplicationCommand.ApplicationCommand in commandsToCreate do
			self:createSlashCommandAsync(command):await()
		end
	end)
end

function DiscordGuild.Interface.new(discordClient: any, guildData: {
	id: string,
	roles: { any },
	emojis: { any },
	[any]: any,
})
	return discordClient.discordCache:getDataOr(CacheType.DiscordGuild, guildData.id, function()
		local guildStruct = {
			discordClient = discordClient
		}

		for index, value in guildData.roles do
			guildData.roles[index] = DiscordGuildRole.new(discordClient, value)
		end

		for index, value in guildData.emojis do
			guildData.emojis[index] = DiscordEmoji.new(discordClient, value)
		end

		for index, value in guildData do
			guildStruct[index] = value
		end

		return Construct(guildStruct, DiscordGuild.Prototype)
	end)
end

export type DiscordGuild = typeof(DiscordGuild.Interface.new())

return DiscordGuild.Interface