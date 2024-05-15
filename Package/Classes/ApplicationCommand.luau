local Enumerate = require("../Utils/Enumerate")
local Construct = require("../Utils/Construct")

local ApplicationCommandOption = require("ApplicationCommandOption")

local DiscordPermissions = require("DiscordPermissions")

--[=[
	@class ApplicationCommand

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local ApplicationCommand = {}

ApplicationCommand.Interface = {}
ApplicationCommand.Prototype = { }

ApplicationCommand.Prototype.type = "ApplicationCommand"

--[=[
	@prop Type { ... }
	@within ApplicationCommand
]=]
ApplicationCommand.Interface.Type = Enumerate.new({
	ChatInput = 1,
	UserInput = 2,
	MessageInput = 3,
})

--[=[
	@prop Context { ... }
	@within ApplicationCommand
]=]
ApplicationCommand.Interface.Context = Enumerate.new({
	Guild = 0,
	BotDM = 1,
	PrivateChannel = 2,
})

--[=[
	@method setType
	@within ApplicationCommand

	@param commandType string

	@return ApplicationCommand

	(yet-to-do!)

	```lua

	```
]=]
function ApplicationCommand.Prototype.setType(self: ApplicationCommand, commandType: number)
	assert(ApplicationCommand.Interface.Type:Is(commandType), `Expected 'commandType' to of enum 'commandType'`)

	self.commandType = commandType

	return self
end

--[=[
	@method setLocalization
	@within ApplicationCommand

	@param localizationCode string

	@return ApplicationCommand

	(yet-to-do!)

	```lua

	```
]=]
function ApplicationCommand.Prototype.setLocalization(self: ApplicationCommand, localizationCode: string)
	self.commandLocalization = localizationCode

	return self
end

--[=[
	@method setDescription
	@within ApplicationCommand

	@param description string

	@return ApplicationCommand

	(yet-to-do!)

	```lua

	```
]=]
function ApplicationCommand.Prototype.setDescription(self: ApplicationCommand, description: string)
	self.commandDescription = description

	return self
end

--[=[
	@method setName
	@within ApplicationCommand

	@param name string

	@return ApplicationCommand

	(yet-to-do!)

	```lua

	```
]=]
function ApplicationCommand.Prototype.setName(self: ApplicationCommand, name: string)
	self.commandName = name

	return self
end

--[=[
	@method setNSFW
	@within ApplicationCommand

	@param isNSFW boolean

	@return ApplicationCommand

	(yet-to-do!)

	```lua

	```
]=]
function ApplicationCommand.Prototype.setNSFW(self: ApplicationCommand, isNSFW: boolean)
	self.commandNSFW = isNSFW

	return self
end

--[=[
	@method setDMPermission
	@within ApplicationCommand

	@param canDM boolean

	@return ApplicationCommand

	(yet-to-do!)

	```lua

	```
]=]
function ApplicationCommand.Prototype.setDMPermission(self: ApplicationCommand, canDM: boolean)
	self.commandDM = canDM

	return self
end

--[=[
	@method setGuildPermissions
	@within ApplicationCommand

	@param permissionObject !DiscordPermissions

	@return ApplicationCommand

	(yet-to-do!)

	```lua

	```
]=]
function ApplicationCommand.Prototype.setGuildPermissions(self: ApplicationCommand, permissionObject: DiscordPermissions.DiscordPermissions)
	self.commandPermissions = permissionObject

	return self
end

--[=[
	@method addOption
	@within ApplicationCommand

	@param commandObject !ApplicationCommandOption

	@return ApplicationCommand

	(yet-to-do!)

	```lua

	```
]=]
function ApplicationCommand.Prototype.addOption(self: ApplicationCommand, commandObject: ApplicationCommandOption.ApplicationCommandOptions)
	table.insert(self.options, commandObject)

	return self
end

--[=[
	@method addOption
	@within ApplicationCommand

	@param commandObject !ApplicationCommandOption

	@return ApplicationCommand

	(yet-to-do!)

	```lua

	```
]=]
function ApplicationCommand.Prototype.setDefaultPermissionEnabled(self: ApplicationCommand, enabled: boolean)
	self.defaultPermissionEnabled = enabled

	return self
end

--[=[
	@method addContext
	@within ApplicationCommand

	@param commandObject !ApplicationCommandOption

	@return ApplicationCommand

	(yet-to-do!)

	```lua

	```
]=]
function ApplicationCommand.Prototype.addContext(self: ApplicationCommand, context: number)
	table.insert(self.contexts, context)

	return self
end

--[=[
	@method toJSONObject
	@within ApplicationCommand

	@return { ... }

	(yet-to-do!)

	```lua

	```
]=]
function ApplicationCommand.Prototype.toJSONObject(self: ApplicationCommand)
	local permissions = "0"
	local contexts = {}
	local options = {}

	for _, commandOption in self.options do
		table.insert(options, commandOption:toJSONObject())
	end

	if self.commandPermissions then
		permissions = self.commandPermissions:getValue()
	end

	for index, context in self.contexts do
		contexts[tostring(index)] = context
	end

	return {
		type = self.commandType,
		name = self.commandName,
		description = self.commandDescription,

		nsfw = self.commandNSFW,

		default_permission = self.defaultPermissionEnabled,
		default_member_permissions = permissions,
		dm_permission = self.commandDM,

		contexts = contexts,

		name_localizations = self.commandLocalization,
		description_localizations = self.commandLocalization,

		options = (#options > 0 and options) or nil,
	}
end

--[=[
	@function new
	@within ApplicationCommand

	@return ApplicationCommand

	(yet-to-do!)

	```lua

	```
]=]
function ApplicationCommand.Interface.new()
	return (Construct({
		choices = {},
		options = {},
		contexts = {}
	}, ApplicationCommand.Prototype) :: unknown) :: ApplicationCommand
end

export type ApplicationCommand = typeof(ApplicationCommand.Prototype) & {
	commandLocalization: string,
	commandDM: boolean,

	commandDescription: string,
	commandName: string,
	commandType: number,
	commandNSFW: boolean,

	defaultPermissionEnabled: boolean?,

	contexts: { number },
	commandPermissions: DiscordPermissions.DiscordPermissions,
	options: { ApplicationCommandOption.ApplicationCommandOptions }
}

return ApplicationCommand.Interface