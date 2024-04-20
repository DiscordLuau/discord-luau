local Enumerate = require("../Utils/Enumerate")
local Construct = require("../Utils/Construct")

local ApplicationCommandObject = require("ApplicationCommandOption")

local DiscordPermissions = require("DiscordPermissions")

--[=[
	@class ApplicationCommand

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local ApplicationCommand = {}

ApplicationCommand.Interface = {}
ApplicationCommand.Prototype = { }

ApplicationCommand.Prototype.type = "ApplicationCommand"

ApplicationCommand.Interface.Type = Enumerate.new({
	ChatInput = 1,
	UserInput = 2,
	MessageInput = 3,
})

function ApplicationCommand.Prototype.setType(self: ApplicationCommand, commandType: string): ApplicationCommand
	assert(ApplicationCommand.Interface.Type:Is(commandType), `Expected 'commandType' to of enum 'CommandType'`)

	self.CommandType = commandType

	return self
end

function ApplicationCommand.Prototype.setLocalization(self: ApplicationCommand, localizationCode: string): ApplicationCommand
	self.CommandLocalization = localizationCode

	return self
end

function ApplicationCommand.Prototype.setDescription(self: ApplicationCommand, description: string): ApplicationCommand
	self.CommandDescription = description

	return self
end

function ApplicationCommand.Prototype.setName(self: ApplicationCommand, name: string): ApplicationCommand
	self.CommandName = name

	return self
end

function ApplicationCommand.Prototype.setNSFW(self: ApplicationCommand, isNSFW: boolean): ApplicationCommand
	self.CommandNSFW = isNSFW

	return self
end

function ApplicationCommand.Prototype.setDMPermission(self: ApplicationCommand, canDM: boolean): ApplicationCommand
	self.CommandDM = canDM

	return self
end

function ApplicationCommand.Prototype:SetGuildPermissions(permissionObject: DiscordPermissions.DiscordPermissions): ApplicationCommand
	self.commandPermissions = permissionObject

	return self
end

function ApplicationCommand.Prototype.setAutocompleteEnabled(self: ApplicationCommand, enabled: boolean): ApplicationCommand
	self.AutocompleteEnabled = enabled

	return self
end

function ApplicationCommand.Prototype.addOption(self: ApplicationCommand, commandObject: ApplicationCommandObject.ApplicationCommandOptions): ApplicationCommand
	table.insert(self.options, commandObject)

	return self
end

function ApplicationCommand.Prototype.destroyOption(self: ApplicationCommand, commandName: string): ApplicationCommand
	for index, commandObject in self.options do
		if commandObject.CommandName ~= commandName then
			continue
		end

		table.remove(self.choices, index)

		return self
	end

	return self
end

function ApplicationCommand.Prototype.toJSONObject(self: ApplicationCommand)
	local permissions = 0
	local options = {}

	for _, commandOption in self.options do
		table.insert(options, commandOption:toJSONObject())
	end

	if self.commandPermissions then
		permissions = self.commandPermissions:getValue()
	end

	return {
		type = self.CommandType,
		name = self.CommandName,
		description = self.CommandDescription,

		default_member_permissions = permissions,
		dm_permission = self.CommandDM,

		name_localizations = self.CommandLocalization,
		description_localizations = self.CommandLocalization,

		options = (#options > 0 and options) or nil,
	}
end

function ApplicationCommand.Interface.new()
	return Construct({
		choices = {},
		options = {}
	}, ApplicationCommand.Prototype)
end

export type ApplicationCommand = typeof(ApplicationCommand.Interface.new())

return ApplicationCommand.Interface