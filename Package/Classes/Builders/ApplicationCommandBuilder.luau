local Enumerate = require("../../Utils/Enumerate")
local Construct = require("../../Utils/Construct")

local ApplicationCommandOptionBuilder = require("ApplicationCommandOptionBuilder")
local DiscordPermissionsBuilder = require("DiscordPermissionsBuilder")

--[=[
	@class ApplicationCommandBuilder

	ApplicationCommandBuilder is used to construct a command for a Discord application, including type, name, description, and options.

	Usage:
	```lua
	local command = ApplicationCommandBuilder.new()
		:setType(ApplicationCommandBuilder.Type.ChatInput)
		:setName("example_command")
		:setDescription("This is an example command.")
		:setNSFW(false)
		:setDMPermission(true)
		:setDefaultPermissionEnabled(true)
		:addOption(ApplicationCommandOptionBuilder.new():setType(ApplicationCommandOptionBuilder.Type.String):setName("option1"):setDescription("An option"))
	```
]=]
local ApplicationCommandBuilder = {}

ApplicationCommandBuilder.Interface = {}
ApplicationCommandBuilder.Prototype = {}

ApplicationCommandBuilder.Prototype.type = "ApplicationCommandBuilder"

--[=[
	@prop Type table
	@within Builders.ApplicationCommandBuilder

	An enumeration of command types.

	- ChatInput: 1
	- UserInput: 2
	- MessageInput: 3
]=]
ApplicationCommandBuilder.Interface.Type = Enumerate.new({
	ChatInput = 1,
	UserInput = 2,
	MessageInput = 3,
})

--[=[
	@prop Context table
	@within Builders.ApplicationCommandBuilder

	An enumeration of command contexts.

	- Guild: 0
	- BotDM: 1
	- PrivateChannel: 2
]=]
ApplicationCommandBuilder.Interface.Context = Enumerate.new({
	Guild = 0,
	BotDM = 1,
	PrivateChannel = 2,
})

--[=[
	Sets the type of the command.
	
	@method setType
	@param commandType number -- The type of the command.
	@within Builders.ApplicationCommandBuilder
	@return Builders.ApplicationCommandBuilder -- Returns the ApplicationCommandBuilder instance for method chaining.
]=]
function ApplicationCommandBuilder.Prototype.setType(self: ApplicationCommandBuilder, commandType: number)
	assert(ApplicationCommandBuilder.Interface.Type:Is(commandType), `Expected 'commandType' to be of enum 'commandType'`)

	self.commandType = commandType

	return self
end

--[=[
	Sets the localization code for the command.
	
	@method setLocalization
	@param localizationCode string -- The localization code.
	@within Builders.ApplicationCommandBuilder
	@return Builders.ApplicationCommandBuilder -- Returns the ApplicationCommandBuilder instance for method chaining.
]=]
function ApplicationCommandBuilder.Prototype.setLocalization(self: ApplicationCommandBuilder, localizationCode: string)
	self.commandLocalization = localizationCode

	return self
end

--[=[
	Sets the description of the command.
	
	@method setDescription
	@param description string -- The description of the command.
	@within Builders.ApplicationCommandBuilder
	@return Builders.ApplicationCommandBuilder -- Returns the ApplicationCommandBuilder instance for method chaining.
]=]
function ApplicationCommandBuilder.Prototype.setDescription(self: ApplicationCommandBuilder, description: string)
	self.commandDescription = description

	return self
end

--[=[
	Sets the name of the command.
	
	@method setName
	@param name string -- The name of the command.
	@within Builders.ApplicationCommandBuilder
	@return Builders.ApplicationCommandBuilder -- Returns the ApplicationCommandBuilder instance for method chaining.
]=]
function ApplicationCommandBuilder.Prototype.setName(self: ApplicationCommandBuilder, name: string)
	self.commandName = name

	return self
end

--[=[
	
	Sets whether the command is NSFW.
	
	@method setNSFW
	@param isNSFW boolean -- Whether the command is NSFW.
	@within Builders.ApplicationCommandBuilder
	@return Builders.ApplicationCommandBuilder -- Returns the ApplicationCommandBuilder instance for method chaining.
]=]
function ApplicationCommandBuilder.Prototype.setNSFW(self: ApplicationCommandBuilder, isNSFW: boolean)
	self.commandNSFW = isNSFW

	return self
end

--[=[
	
	Sets whether the command can be used in DMs.
	
	@method setDMPermission
	@param canDM boolean -- Whether the command can be used in DMs.
	@within Builders.ApplicationCommandBuilder
	@return Builders.ApplicationCommandBuilder -- Returns the ApplicationCommandBuilder instance for method chaining.
	]=]
function ApplicationCommandBuilder.Prototype.setDMPermission(self: ApplicationCommandBuilder, canDM: boolean)
	self.commandDM = canDM

	return self
end

--[=[
	
	Sets the required permissions for the command in a guild.
	
	@method setGuildPermissions
	@param permissionObject DiscordPermissionsBuilder -- The permissions required for the command.
	@within Builders.ApplicationCommandBuilder
	@return Builders.ApplicationCommandBuilder -- Returns the ApplicationCommandBuilder instance for method chaining.
]=]
function ApplicationCommandBuilder.Prototype.setGuildPermissions(self: ApplicationCommandBuilder, permissionObject: DiscordPermissionsBuilder.DiscordPermissionsBuilder)
	self.commandPermissions = permissionObject

	return self
end

--[=[
	Adds an option to the command.
	
	@method addOption
	@param commandObject ApplicationCommandOptionBuilder -- The option to add.
	@within Builders.ApplicationCommandBuilder
	@return Builders.ApplicationCommandBuilder -- Returns the ApplicationCommandBuilder instance for method chaining.
]=]
function ApplicationCommandBuilder.Prototype.addOption(self: ApplicationCommandBuilder, commandObject: ApplicationCommandOptionBuilder.ApplicationCommandOptionBuilder)
	table.insert(self.options, commandObject)

	return self
end

--[=[
	Sets whether the command has default permission enabled.
	
	@method setDefaultPermissionEnabled
	@param enabled boolean -- Whether default permission is enabled.
	@within Builders.ApplicationCommandBuilder
	@return Builders.ApplicationCommandBuilder -- Returns the ApplicationCommandBuilder instance for method chaining.
]=]
function ApplicationCommandBuilder.Prototype.setDefaultPermissionEnabled(self: ApplicationCommandBuilder, enabled: boolean)
	self.defaultPermissionEnabled = enabled

	return self
end

--[=[
	Adds a context to the command.
	
	@method addContext
	@param context number -- The context to add.
	@within Builders.ApplicationCommandBuilder
	@return Builders.ApplicationCommandBuilder -- Returns the ApplicationCommandBuilder instance for method chaining.
]=]
function ApplicationCommandBuilder.Prototype.addContext(self: ApplicationCommandBuilder, context: number)
	table.insert(self.contexts, context)

	return self
end

--[=[
	Converts the command to a JSON object that can be sent to the Discord API.
	
	@method toJSONObject
	@within Builders.ApplicationCommandBuilder
	@return table -- The JSON representation of the command.
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
	Creates a new instance of ApplicationCommandBuilder.
	
	@function new
	@within Builders.ApplicationCommandBuilder
	@return Builders.ApplicationCommandBuilder -- A new instance of ApplicationCommandBuilder.
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
