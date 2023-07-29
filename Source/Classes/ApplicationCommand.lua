local Enumeration = require("../Dependencies/Enumeration")

local ApplicationCommand = {}

ApplicationCommand.Type = "ApplicationCommand"

ApplicationCommand.Internal = {}
ApplicationCommand.Interface = {}
ApplicationCommand.Prototype = {
	Internal = ApplicationCommand.Internal,
}

ApplicationCommand.Interface.Type = Enumeration.new({
	ChatInput = 1,
	UserInput = 2,
	MessageInput = 3,
})

function ApplicationCommand.Prototype:SetType(commandType)
	assert(ApplicationCommand.Interface.Type:Is(commandType), `Expected 'commandType' to of class 'CommandType'`)

	self.CommandType = commandType

	return self
end

function ApplicationCommand.Prototype:SetLocalization(localizationCode)
	self.CommandLocalization = localizationCode

	return self
end

function ApplicationCommand.Prototype:SetDescription(description)
	self.CommandDescription = description

	return self
end

function ApplicationCommand.Prototype:SetName(name)
	self.CommandName = name

	return self
end

function ApplicationCommand.Prototype:SetNSFW(isNSFW)
	self.CommandNSFW = isNSFW

	return self
end

function ApplicationCommand.Prototype:SetDMPermission(canDM)
	self.CommandDM = canDM

	return self
end

function ApplicationCommand.Prototype:SetGuildPermissions(permissionObject)
	self.CommandPermissions = permissionObject

	return self
end

function ApplicationCommand.Prototype:SetAutocompleteEnabled(enabled)
	self.AutocompleteEnabled = enabled

	return self
end

function ApplicationCommand.Prototype:AddOption(commandObject)
	table.insert(self.Options, commandObject)

	return self
end

function ApplicationCommand.Prototype:DestroyOption(commandName)
	for index, commandObject in self.Options do
		if commandObject.CommandName ~= commandName then
			continue
		end

		table.remove(self.Choices, index)

		return self
	end

	return self
end

function ApplicationCommand.Prototype:ToJSONObject()
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

function ApplicationCommand.Prototype:ToString()
	return `{ApplicationCommand.Type}<{self.Name or "Unknown Command"}>`
end

function ApplicationCommand.Interface.new()
	return setmetatable({
		Choices = {},
		Options = {}
	}, {
		__index = ApplicationCommand.Prototype,
		__type = ApplicationCommand.Type,
		__tostring = function(self)
			return self:ToString()
		end,
	})
end

return ApplicationCommand.Interface
