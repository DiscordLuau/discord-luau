local Future = require("@Vendor/Future")

local Construct = require("@Utils/Construct")

local Resolvable = require("../Network/Resolvable")

local CommandBuilder = require("../Builders/CommandBuilder")

local DiscordEndpoints = require("@Data/DiscordEndpoints")

local ResolvableType = require("@Enums/ResolveableType")
local CacheType = require("@Enums/CacheType")

--[=[
	@class Objects.DiscordApplication

	The `DiscordApplication` class provides methods to interact with Discord application commands such as creating, deleting, editing, fetching, and setting global application commands.
]=]

--[=[
	@prop id string The unique identifier of the Discord application.
	@within Objects.DiscordApplication
]=]

--[=[
	@prop flags number The flags associated with the Discord application.
	@within Objects.DiscordApplication
]=]

local DiscordApplication = {}

DiscordApplication.Prototype = {}
DiscordApplication.Interface = {}

DiscordApplication.Prototype.type = "DiscordApplication"

--[=[
	@method createSlashCommandAsync
	@param command CommandBuilder.CommandBuilder The command to create.
	@within Objects.DiscordApplication
	@return Future<CommandResponse>

	Creates a new slash command for the Discord application.
]=]
function DiscordApplication.Prototype.createSlashCommandAsync(
	self: DiscordApplication,
	command: CommandBuilder.CommandBuilder
)
	return Future.try(function()
		return self.discordClient.discordGateway
			:postAsync(
				string.format(DiscordEndpoints.CreateGlobalApplicationCommand, self.id),
				command:toPayloadObject()
			)
			:await()
	end)
end

--[=[
	@method deleteSlashCommandAsync
	@param commandId string The ID of the command to delete.
	@within Objects.DiscordApplication
	@return Future<CommandResponse>

	Deletes an existing slash command from the Discord application.
]=]
function DiscordApplication.Prototype.deleteSlashCommandAsync(self: DiscordApplication, commandId: string)
	return Future.try(function()
		return self.discordClient.discordGateway
			:deleteAsync(string.format(DiscordEndpoints.DeleteGlobalApplicationCommand, self.id, commandId))
			:await()
	end)
end

--[=[
	@method editSlashCommandAsync
	@param commandId string The ID of the command to edit.
	@param command CommandBuilder.CommandBuilder The updated command data.
	@within Objects.DiscordApplication
	@return Future<CommandResponse>

	Edits an existing slash command for the Discord application.
]=]
function DiscordApplication.Prototype.editSlashCommandAsync(
	self: DiscordApplication,
	commandId: string,
	command: CommandBuilder.CommandBuilder
)
	return Future.try(function()
		return self.discordClient.discordGateway
			:patchAsync(
				string.format(DiscordEndpoints.EditGlobalApplicationCommand, self.id, commandId),
				command:toPayloadObject()
			)
			:await()
	end)
end

--[=[
	@method fetchSlashCommandsAsync
	@within Objects.DiscordApplication
	@return Future<{ApplicationCommand}>

	Fetches all existing slash commands for the Discord application.
]=]
function DiscordApplication.Prototype.fetchSlashCommandsAsync(self: DiscordApplication)
	return Future.try(function()
		return self.discordClient.discordGateway
			:getAsync(string.format(DiscordEndpoints.GetGlobalApplicationCommands, self.id))
			:await()
	end)
end

--[=[
	@method setSlashCommandsAsync
	@param commands {CommandBuilder.CommandBuilder} The list of commands to set.
	@within Objects.DiscordApplication
	@return Future<nil>

	Sets the slash commands for the Discord application, updating existing ones and creating or deleting as necessary.
]=]
function DiscordApplication.Prototype.setSlashCommandsAsync(
	self: DiscordApplication,
	commands: { CommandBuilder.CommandBuilder }
)
	return Future.try(function()
		local commandObjects = {}

		for index, commandBuilder in commands do
			commandObjects[index] = commandBuilder:toPayloadObject():resolve()
		end

		return self.discordClient.discordGateway
			:putAsync(
				string.format(DiscordEndpoints.OverwriteGlobalApplicationCommand, self.id),
				Resolvable.new(ResolvableType.JSON, commandObjects)
			)
			:await()
	end)
end

--[=[
	@function new
	@param discordClient any The Discord client instance.
	@param applicationData {id: string, flags: number} The application data.
	@within Objects.DiscordApplication
	@return DiscordApplication

	Creates a new instance of the DiscordApplication.
]=]
function DiscordApplication.Interface.new(
	discordClient: any,
	applicationData: {
		id: string,
		flags: number,
	}
)
	return discordClient.discordCache:getDataOr(CacheType.Application, applicationData.id, function()
		return Construct({
			id = applicationData.id,
			flags = applicationData.flags,

			discordClient = discordClient,
		}, DiscordApplication.Prototype)
	end)
end

export type DiscordApplication = typeof(DiscordApplication.Prototype) & {
	id: string,
	flags: number,

	discordClient: any,
}

return DiscordApplication.Interface
