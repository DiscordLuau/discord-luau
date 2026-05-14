--[=[
	@class Utilities

	Interface for the discord-luau Utilities package
]=]

return {
	validateKebabCase = require("@self/validateKebabCase"),
	validateCommandName = require("@self/validateCommandName"),
	createGuid = require("@self/createGuid"),
	coroutineRun = require("@self/coroutine/run"),
	tableReflect = require("@self/table/reflect"),
}
