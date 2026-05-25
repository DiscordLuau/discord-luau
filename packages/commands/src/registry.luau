--[=[
	@class Commands.Registry
	@__index Prototype

	In-memory store mapping command names to their definitions.
]=]

--[=[
	@prop commands { [string]: command.CommandDefinition }
	@within Commands.Registry
]=]

local command = require("./command")

local Registry = {}

Registry.Interface = {}
Registry.Prototype = {}

--[=[
	@within Commands.Registry

	Adds or overwrites a command definition keyed by its name.
]=]
function Registry.Prototype.set(self: Registry, commandDefinition: command.CommandDefinition)
	self.commands[commandDefinition.command.name] = commandDefinition
end

--[=[
	@within Commands.Registry

	Removes a command definition by name.
]=]
function Registry.Prototype.remove(self: Registry, name: string)
	self.commands[name] = nil
end

--[=[
	@within Commands.Registry

	Returns the definition for a single command, or nil if not registered.
]=]
function Registry.Prototype.get(self: Registry, name: string): command.CommandDefinition?
	return self.commands[name]
end

--[=[
	@within Commands.Registry

	Returns all registered command definitions as an array.
]=]
function Registry.Prototype.getAll(self: Registry): { command.CommandDefinition }
	local result = {}

	for _, commandDefinition in self.commands do
		table.insert(result, commandDefinition)
	end

	return result
end

--[=[
	@within Commands.Registry

	Constructs a new empty registry.
]=]
function Registry.Interface.new(): Registry
	return setmetatable({ commands = {} } :: Registry, { __index = Registry.Prototype })
end

export type Registry = typeof(Registry.Prototype) & {
	commands: { [string]: command.CommandDefinition },
}

return Registry.Interface
