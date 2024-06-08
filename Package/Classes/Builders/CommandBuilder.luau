local Enumerate = require("../../Utils/Enumerate")
local Construct = require("../../Utils/Construct")

local CommandOptionBuilder = require("CommandOptionBuilder")
local PermissionsBuilder = require("PermissionsBuilder")

local ResolvableType = require("../../Enums/ResolveableType")
local Resolvable = require("../Network/Resolvable")

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
	- UserContextAction: 2
	- MessageContextAction: 3
]=]
CommandBuilder.Interface.Type = Enumerate.new({
	ChatInput = 1,
	UserContextAction = 2,
	MessageContextAction = 3,
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
	@prop IntegrationType table
	@within Builders.CommandBuilder

	An enumeration of command integration contexts.

	- GuildCommand: 0
	- UserCommand: 1
]=]
CommandBuilder.Interface.IntegrationType = Enumerate.new({
	GuildCommand = 0,
	UserCommand = 1,
})

--[=[
	Sets the type of the command.
	
	@method setType
	@param commandType number -- The type of the command.
	@within Builders.CommandBuilder
	@return Builders.CommandBuilder -- Returns the CommandBuilder instance for method chaining.
]=]
function CommandBuilder.Prototype.setType(self: CommandBuilder, commandType: number)
	CommandBuilder.Interface.Type:Assert(commandType)

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
	Adds an intergration to the command.
	
	@method addIntegration
	@param integration IntegrationType 
	@within Builders.CommandBuilder
	@return Builders.CommandBuilder -- Returns the CommandBuilder instance for method chaining.
]=]
function CommandBuilder.Prototype.addIntegration(self: CommandBuilder, integration: number)
	table.insert(self.integrations, integration)

	return self
end

--[=[
	Converts the command to a JSON object that can be sent to the Discord API.
	
	@method toPayloadObject
	@within Builders.CommandBuilder
	@return Network.Resolvable
]=]
function CommandBuilder.Prototype.toPayloadObject(self: CommandBuilder)
	local permissions = "0"
	local options = {}

	for _, commandOption in self.options do
		table.insert(options, (commandOption:toPayloadObject() :: any):resolve())
	end

	if self.commandPermissions then
		permissions = self.commandPermissions:getValue()
	end

	return Resolvable.new(ResolvableType.JSON, {
		type = self.commandType,
		name = self.commandName,
		description = self.commandDescription,

		nsfw = self.commandNSFW,

		default_permission = self.defaultPermissionEnabled,
		default_member_permissions = permissions,
		dm_permission = self.commandDM,

		integration_types = self.integrations,
		contexts = self.contexts,

		name_localizations = self.commandLocalization,
		description_localizations = self.commandLocalization,

		options = (#options > 0 and options) or nil,
	})
end

--[=[
	Creates a new instance of CommandBuilder.
	
	@function new
	@within Builders.CommandBuilder
	@return Builders.CommandBuilder -- A new instance of CommandBuilder.
]=]
function CommandBuilder.Interface.new()
	return (
		Construct({
			choices = {},
			options = {},
			contexts = {},
			integrations = {},
		}, CommandBuilder.Prototype) :: unknown
	) :: CommandBuilder
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
	integrations: { number },
	commandPermissions: PermissionsBuilder.PermissionsBuilder,
	options: { CommandOptionBuilder.CommandOptionBuilder },
}

return CommandBuilder.Interface
