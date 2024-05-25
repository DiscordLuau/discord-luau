local Enumerate = require("../../Utils/Enumerate")
local Construct = require("../../Utils/Construct")

local CommandOptionBuilder = require("CommandOptionBuilder")
local PermissionsBuilder = require("PermissionsBuilder")

--[=[
	@class Builders.CommandBuilder

	CommandBuilder is used to construct a command for a Discord application, including type, name, description, and options.

	Usage:
	```lua
	local command = CommandBuilder.new()
		:setType(CommandBuilder.Type.ChatInput)
		:setName("example_command")
		:setDescription("This is an example command.")
		:setNSFW(false)
		:setDMPermission(true)
		:setDefaultPermissionEnabled(true)
		:addOption(CommandOptionBuilder.new():setType(CommandOptionBuilder.Type.String):setName("option1"):setDescription("An option"))
	```
]=]
local CommandBuilder = {}

CommandBuilder.Interface = {}
CommandBuilder.Prototype = {}

CommandBuilder.Prototype.type = "CommandBuilder"

--[=[
	@prop Type table
	@within Builders.CommandBuilder

	An enumeration of command types.

	- ChatInput: 1
	- UserInput: 2
	- MessageInput: 3
]=]
CommandBuilder.Interface.Type = Enumerate.new({
	ChatInput = 1,
	UserInput = 2,
	MessageInput = 3,
})

--[=[
	@prop Context table
	@within Builders.CommandBuilder

	An enumeration of command contexts.

	- Guild: 0
	- BotDM: 1
	- PrivateChannel: 2
]=]
CommandBuilder.Interface.Context = Enumerate.new({
	Guild = 0,
	BotDM = 1,
	PrivateChannel = 2,
})

--[=[
	Sets the type of the command.
	
	@method setType
	@param commandType number -- The type of the command.
	@within Builders.CommandBuilder
	@return Builders.CommandBuilder -- Returns the CommandBuilder instance for method chaining.
]=]
function CommandBuilder.Prototype.setType(self: CommandBuilder, commandType: number)
	assert(CommandBuilder.Interface.Type:Is(commandType), `Expected 'commandType' to be of enum 'commandType'`)

	self.commandType = commandType

	return self
end

--[=[
	Sets the localization code for the command.
	
	@method setLocalization
	@param localizationCode string -- The localization code.
	@within Builders.CommandBuilder
	@return Builders.CommandBuilder -- Returns the CommandBuilder instance for method chaining.
]=]
function CommandBuilder.Prototype.setLocalization(self: CommandBuilder, localizationCode: string)
	self.commandLocalization = localizationCode

	return self
end

--[=[
	Sets the description of the command.
	
	@method setDescription
	@param description string -- The description of the command.
	@within Builders.CommandBuilder
	@return Builders.CommandBuilder -- Returns the CommandBuilder instance for method chaining.
]=]
function CommandBuilder.Prototype.setDescription(self: CommandBuilder, description: string)
	self.commandDescription = description

	return self
end

--[=[
	Sets the name of the command.
	
	@method setName
	@param name string -- The name of the command.
	@within Builders.CommandBuilder
	@return Builders.CommandBuilder -- Returns the CommandBuilder instance for method chaining.
]=]
function CommandBuilder.Prototype.setName(self: CommandBuilder, name: string)
	self.commandName = name

	return self
end

--[=[
	
	Sets whether the command is NSFW.
	
	@method setNSFW
	@param isNSFW boolean -- Whether the command is NSFW.
	@within Builders.CommandBuilder
	@return Builders.CommandBuilder -- Returns the CommandBuilder instance for method chaining.
]=]
function CommandBuilder.Prototype.setNSFW(self: CommandBuilder, isNSFW: boolean)
	self.commandNSFW = isNSFW

	return self
end

--[=[
	
	Sets whether the command can be used in DMs.
	
	@method setDMPermission
	@param canDM boolean -- Whether the command can be used in DMs.
	@within Builders.CommandBuilder
	@return Builders.CommandBuilder -- Returns the CommandBuilder instance for method chaining.
	]=]
function CommandBuilder.Prototype.setDMPermission(self: CommandBuilder, canDM: boolean)
	self.commandDM = canDM

	return self
end

--[=[
	
	Sets the required permissions for the command in a guild.
	
	@method setGuildPermissions
	@param permissionObject PermissionsBuilder -- The permissions required for the command.
	@within Builders.CommandBuilder
	@return Builders.CommandBuilder -- Returns the CommandBuilder instance for method chaining.
]=]
function CommandBuilder.Prototype.setGuildPermissions(
	self: CommandBuilder,
	permissionObject: PermissionsBuilder.PermissionsBuilder
)
	self.commandPermissions = permissionObject

	return self
end

--[=[
	Adds an option to the command.
	
	@method addOption
	@param commandObject CommandOptionBuilder -- The option to add.
	@within Builders.CommandBuilder
	@return Builders.CommandBuilder -- Returns the CommandBuilder instance for method chaining.
]=]
function CommandBuilder.Prototype.addOption(
	self: CommandBuilder,
	commandObject: CommandOptionBuilder.CommandOptionBuilder
)
	table.insert(self.options, commandObject)

	return self
end

--[=[
	Sets whether the command has default permission enabled.
	
	@method setDefaultPermissionEnabled
	@param enabled boolean -- Whether default permission is enabled.
	@within Builders.CommandBuilder
	@return Builders.CommandBuilder -- Returns the CommandBuilder instance for method chaining.
]=]
function CommandBuilder.Prototype.setDefaultPermissionEnabled(self: CommandBuilder, enabled: boolean)
	self.defaultPermissionEnabled = enabled

	return self
end

--[=[
	Adds a context to the command.
	
	@method addContext
	@param context number -- The context to add.
	@within Builders.CommandBuilder
	@return Builders.CommandBuilder -- Returns the CommandBuilder instance for method chaining.
]=]
function CommandBuilder.Prototype.addContext(self: CommandBuilder, context: number)
	table.insert(self.contexts, context)

	return self
end

--[=[
	Converts the command to a JSON object that can be sent to the Discord API.
	
	@method toJSONObject
	@within Builders.CommandBuilder
	@return table -- The JSON representation of the command.
]=]
function CommandBuilder.Prototype.toJSONObject(self: CommandBuilder)
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
	Creates a new instance of CommandBuilder.
	
	@function new
	@within Builders.CommandBuilder
	@return Builders.CommandBuilder -- A new instance of CommandBuilder.
]=]
function CommandBuilder.Interface.new(): CommandBuilder
	return Construct({
		choices = {},
		options = {},
		contexts = {},
	}, CommandBuilder.Prototype) :: any
end

export type CommandBuilder = typeof(CommandBuilder.Prototype) & {
	commandLocalization: string,
	commandDM: boolean,

	commandDescription: string,
	commandName: string,
	commandType: number,
	commandNSFW: boolean,

	defaultPermissionEnabled: boolean?,

	contexts: { number },
	commandPermissions: PermissionsBuilder.PermissionsBuilder,
	options: { CommandOptionBuilder.CommandOptionBuilder },
}

return CommandBuilder.Interface
