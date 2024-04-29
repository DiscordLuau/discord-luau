local Construct = require("../../Utils/Construct")

local Future = require("../../Vendor/Future")

local ApplicationCommand = require("../ApplicationCommand")

local DiscordEndpoints = require("../../Enums/DiscordEndpoints")
local CacheType = require("../../Enums/CacheType")

--[=[
	@class Internal.DiscordApplication

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local DiscordApplication = {}

DiscordApplication.Prototype = {}
DiscordApplication.Interface = {}

DiscordApplication.Prototype.type = "DiscordApplication"

function DiscordApplication.Prototype.createSlashCommandAsync(self: DiscordApplication, command: ApplicationCommand.ApplicationCommand)
	return Future.try(function()
		return self.discordClient.discordGateway:postAsync(
			string.format(DiscordEndpoints.CreateGlobalApplicationCommand, self.id),
			command:toJSONObject()
		):await()
	end)
end

function DiscordApplication.Prototype.deleteSlashCommandAsync(self: DiscordApplication, commandId: string)
	return Future.try(function()
		return self.discordClient.discordGateway:deleteAsync(
			string.format(DiscordEndpoints.DeleteGlobalApplicationCommand, self.id, commandId)
		):await()
	end)
end

function DiscordApplication.Prototype.editSlashCommandAsync(self: DiscordApplication, commandId: string, command: ApplicationCommand.ApplicationCommand)
	return Future.try(function()
		return self.discordClient.discordGateway:patchAsync(
			string.format(DiscordEndpoints.EditGlobalApplicationCommand, self.id, commandId),
			command:toJSONObject()
		):await()
	end)
end

function DiscordApplication.Prototype.fetchSlashCommandsAsync(self: DiscordApplication)
	return Future.try(function()
		return self.discordClient.discordGateway:getAsync(
			string.format(DiscordEndpoints.GetGlobalApplicationCommands, self.id)
		):await()
	end)
end

function DiscordApplication.Prototype.setSlashCommandsAsync(self: DiscordApplication, commands: { ApplicationCommand.ApplicationCommand })
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

function DiscordApplication.Interface.new(discordClient: any, applicationData: {
	id: string,
	flags: number
})
	return discordClient.discordCache:getDataOr(CacheType.Application, applicationData.id, function()
		return Construct({
			id = applicationData.id,
			flags = applicationData.flags,
	
			discordClient = discordClient
		}, DiscordApplication.Prototype)
	end)
end

export type DiscordApplication = typeof(DiscordApplication.Interface.new())

return DiscordApplication.Interface