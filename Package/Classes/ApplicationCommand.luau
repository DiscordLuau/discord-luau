local Enumerate = require("../Utils/Enumerate")
local Construct = require("../Utils/Construct")

local ApplicationCommandObject = require("ApplicationCommandOption")

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

function ApplicationCommand.Prototype.setType(self: ApplicationCommand, commandType: string)
	assert(ApplicationCommand.Interface.Type:Is(commandType), `Expected 'commandType' to of enum 'CommandType'`)

	self.CommandType = commandType

	return self
end

function ApplicationCommand.Prototype.setLocalization(self: ApplicationCommand, localizationCode: string)
	self.CommandLocalization = localizationCode

	return self
end

function ApplicationCommand.Prototype.setDescription(self: ApplicationCommand, description: string)
	self.CommandDescription = description

	return self
end

function ApplicationCommand.Prototype.setName(self: ApplicationCommand, name: string)
	self.CommandName = name

	return self
end

function ApplicationCommand.Prototype.setNSFW(self: ApplicationCommand, isNSFW: boolean)
	self.CommandNSFW = isNSFW

	return self
end

function ApplicationCommand.Prototype.setDMPermission(self: ApplicationCommand, canDM: boolean)
	self.CommandDM = canDM

	return self
end

-- function ApplicationCommand.Prototype:SetGuildPermissions(permissionObject: any)
-- 	self.CommandPermissions = permissionObject

-- 	return self
-- end

function ApplicationCommand.Prototype.setAutocompleteEnabled(self: ApplicationCommand, enabled: boolean)
	self.AutocompleteEnabled = enabled

	return self
end

function ApplicationCommand.Prototype.addOption(self: ApplicationCommand, commandObject: ApplicationCommandObject.ApplicationCommandOptions)
	table.insert(self.Options, commandObject)

	return self
end

function ApplicationCommand.Prototype.destroyOption(self: ApplicationCommand, commandName: string)
	for index, commandObject in self.Options do
		if commandObject.CommandName ~= commandName then
			continue
		end

		table.remove(self.Choices, index)

		return self
	end

	return self
end

function ApplicationCommand.Prototype.toJSONObject(self: ApplicationCommand)
	local permissionsInt = 0
	local options = {}

	for _, commandOption in self.Options do
		table.insert(options, commandOption:ToJSONObject())
	end

	if self.CommandPermissions then
		permissionsInt = self.CommandPermissions:GetValue()
	end

	return {
		type = self.CommandType,
		name = self.CommandName,
		description = self.CommandDescription,

		default_member_permissions = permissionsInt,
		dm_permission = self.CommandDM,

		name_localizations = self.CommandLocalization,
		description_localizations = self.CommandLocalization,

		options = (#options > 0 and options) or nil,
	}
end

function ApplicationCommand.Interface.new()
	return Construct({
		Choices = {},
		Options = {}
	}, ApplicationCommand.Prototype)
end

export type ApplicationCommand = typeof(ApplicationCommand.Interface.new())

return ApplicationCommand.Interface