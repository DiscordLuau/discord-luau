local Enumerate = require("../../Utils/Enumerate")
local Construct = require("../../Utils/Construct")

local ApplicationCommandOptionBuilder = require("ApplicationCommandOptionBuilder")

local DiscordPermissionsBuilder = require("DiscordPermissionsBuilder")

--[=[
	@class ApplicationCommandBuilder

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local ApplicationCommandBuilder = {}

ApplicationCommandBuilder.Interface = {}
ApplicationCommandBuilder.Prototype = { }

ApplicationCommandBuilder.Prototype.type = "ApplicationCommandBuilder"

--[=[
	@prop Type { ... }
	@within ApplicationCommandBuilder
]=]
ApplicationCommandBuilder.Interface.Type = Enumerate.new({
	ChatInput = 1,
	UserInput = 2,
	MessageInput = 3,
})

--[=[
	@prop Context { ... }
	@within ApplicationCommandBuilder
]=]
ApplicationCommandBuilder.Interface.Context = Enumerate.new({
	Guild = 0,
	BotDM = 1,
	PrivateChannel = 2,
})

--[=[
	@method setType
	@within ApplicationCommandBuilder

	@param commandType string

	@return ApplicationCommandBuilder

	(yet-to-do!)

	```lua

	```
]=]
function ApplicationCommandBuilder.Prototype.setType(self: ApplicationCommandBuilder, commandType: number)
	assert(ApplicationCommandBuilder.Interface.Type:Is(commandType), `Expected 'commandType' to of enum 'commandType'`)

	self.commandType = commandType

	return self
end

--[=[
	@method setLocalization
	@within ApplicationCommandBuilder

	@param localizationCode string

	@return ApplicationCommandBuilder

	(yet-to-do!)

	```lua

	```
]=]
function ApplicationCommandBuilder.Prototype.setLocalization(self: ApplicationCommandBuilder, localizationCode: string)
	self.commandLocalization = localizationCode

	return self
end

--[=[
	@method setDescription
	@within ApplicationCommandBuilder

	@param description string

	@return ApplicationCommandBuilder

	(yet-to-do!)

	```lua

	```
]=]
function ApplicationCommandBuilder.Prototype.setDescription(self: ApplicationCommandBuilder, description: string)
	self.commandDescription = description

	return self
end

--[=[
	@method setName
	@within ApplicationCommandBuilder

	@param name string

	@return ApplicationCommandBuilder

	(yet-to-do!)

	```lua

	```
]=]
function ApplicationCommandBuilder.Prototype.setName(self: ApplicationCommandBuilder, name: string)
	self.commandName = name

	return self
end

--[=[
	@method setNSFW
	@within ApplicationCommandBuilder

	@param isNSFW boolean

	@return ApplicationCommandBuilder

	(yet-to-do!)

	```lua

	```
]=]
function ApplicationCommandBuilder.Prototype.setNSFW(self: ApplicationCommandBuilder, isNSFW: boolean)
	self.commandNSFW = isNSFW

	return self
end

--[=[
	@method setDMPermission
	@within ApplicationCommandBuilder

	@param canDM boolean

	@return ApplicationCommandBuilder

	(yet-to-do!)

	```lua

	```
]=]
function ApplicationCommandBuilder.Prototype.setDMPermission(self: ApplicationCommandBuilder, canDM: boolean)
	self.commandDM = canDM

	return self
end

--[=[
	@method setGuildPermissions
	@within ApplicationCommandBuilder

	@param permissionObject !DiscordPermissionsBuilder

	@return ApplicationCommandBuilder

	(yet-to-do!)

	```lua

	```
]=]
function ApplicationCommandBuilder.Prototype.setGuildPermissions(self: ApplicationCommandBuilder, permissionObject: DiscordPermissionsBuilder.DiscordPermissionsBuilder)
	self.commandPermissions = permissionObject

	return self
end

--[=[
	@method addOption
	@within ApplicationCommandBuilder

	@param commandObject !ApplicationCommandOptionBuilder

	@return ApplicationCommandBuilder

	(yet-to-do!)

	```lua

	```
]=]
function ApplicationCommandBuilder.Prototype.addOption(self: ApplicationCommandBuilder, commandObject: ApplicationCommandOptionBuilder.ApplicationCommandOptionBuilder)
	table.insert(self.options, commandObject)

	return self
end

--[=[
	@method addOption
	@within ApplicationCommandBuilder

	@param commandObject !ApplicationCommandOptionBuilder

	@return ApplicationCommandBuilder

	(yet-to-do!)

	```lua

	```
]=]
function ApplicationCommandBuilder.Prototype.setDefaultPermissionEnabled(self: ApplicationCommandBuilder, enabled: boolean)
	self.defaultPermissionEnabled = enabled

	return self
end

--[=[
	@method addContext
	@within ApplicationCommandBuilder

	@param commandObject !ApplicationCommandOptionBuilder

	@return ApplicationCommandBuilder

	(yet-to-do!)

	```lua

	```
]=]
function ApplicationCommandBuilder.Prototype.addContext(self: ApplicationCommandBuilder, context: number)
	table.insert(self.contexts, context)

	return self
end

--[=[
	@method toJSONObject
	@within ApplicationCommandBuilder

	@return { ... }

	(yet-to-do!)

	```lua

	```
]=]
function ApplicationCommandBuilder.Prototype.toJSONObject(self: ApplicationCommandBuilder)
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
	@within ApplicationCommandBuilder

	@return ApplicationCommandBuilder

	(yet-to-do!)

	```lua

	```
]=]
function ApplicationCommandBuilder.Interface.new(): ApplicationCommandBuilder
	return Construct({
		choices = {},
		options = {},
		contexts = {}
	}, ApplicationCommandBuilder.Prototype) :: any
end

export type ApplicationCommandBuilder = typeof(ApplicationCommandBuilder.Prototype) & {
	commandLocalization: string,
	commandDM: boolean,

	commandDescription: string,
	commandName: string,
	commandType: number,
	commandNSFW: boolean,

	defaultPermissionEnabled: boolean?,

	contexts: { number },
	commandPermissions: DiscordPermissionsBuilder.DiscordPermissionsBuilder,
	options: { ApplicationCommandOptionBuilder.ApplicationCommandOptionBuilder }
}

return ApplicationCommandBuilder.Interface