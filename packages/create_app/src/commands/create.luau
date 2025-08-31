local CliBuilder = require("../../luau_packages/cli_builder")
local StdPolyfills = require("../../lune_packages/std_polyfills")

local Logger = require("../objects/logger")

local command = CliBuilder.command
local argument = CliBuilder.argument

local OS_SLASH_MAP = table.freeze({
	["linux"] = "/",
	["macos"] = "/",
	["windows"] = "\\",
})

local OS_HOME_VARS = table.freeze({
	["linux"] = "HOME",
	["macos"] = "HOME",
	["windows"] = "USERPROFILE",
})

local INFORMATION_TO_QUERY = table.freeze({
	ProjectName = "What should this project be called?",
	UseGit = "Should this project use Git?",
	DiscordToken = "What is the discord bot token?",
})

local INFORMATION_QUERY_ORDER = table.freeze({
	"ProjectName",
	"UseGit",
	"DiscordToken",
})

local function resolveDirectory(directory: string?): string?
	if not directory or directory == "." then
		return StdPolyfills.process.getCwd()
	end

	local os = StdPolyfills.process.getPlatform()
	local separator = OS_SLASH_MAP[os] or "/"
	local resolvedPath: string

	if string.sub(directory, 1, 1) == "~" then
		local homeVarName = OS_HOME_VARS[os]
		local home = homeVarName and StdPolyfills.process.getEnv()[homeVarName]

		if not home then
			Logger:error(
				`Unable to resolve ${OS_HOME_VARS[os]} environment variable! Does this environment variable exist?`
			)

			return nil
		end

		local restOfPath = string.sub(directory, 2)

		if restOfPath == "" then
			resolvedPath = home
		else
			if string.sub(restOfPath, 1, 1) == "/" or string.sub(restOfPath, 1, 1) == "\\" then
				restOfPath = string.sub(restOfPath, 2)
			end

			resolvedPath = home .. separator .. restOfPath
		end
	elseif (string.sub(directory, 1, 1) == "/") or (string.match(directory, "^%a:\\") ~= nil) then
		return directory
	else
		local cwd = StdPolyfills.process.getCwd()
		resolvedPath = cwd .. separator .. directory
	end

	if StdPolyfills.fileSystem.isDir(resolvedPath) then
		return resolvedPath
	else
		return nil
	end
end

local function queryInformation(): Information
	local information = {}

	for _, enum in INFORMATION_QUERY_ORDER do
		local question = INFORMATION_TO_QUERY[enum]

		print(question)

		local answer = StdPolyfills.stdio.prompt("> ")

		StdPolyfills.stdio.write("\x1b[1A\x1b[2K")

		information[enum] = answer
	end

	return information :: Information
end

local function verifyInformation(information: Information)
	for _, enum in INFORMATION_QUERY_ORDER do
		local question = INFORMATION_TO_QUERY[enum]

		print(`"{question}" --> "{information[enum]}"`)
	end

	print("")
	print("Do these answers look correct?")

	local answer = StdPolyfills.stdio.prompt("> ")

	for i = 1, 2 + #INFORMATION_QUERY_ORDER do
		StdPolyfills.stdio.write("\x1b[1A\x1b[2K")
	end

	return answer == "y"
end

type Information = {
	ProjectName: string,
	UseGit: string,
	DiscordToken: string,
}

return command
	.new()
	:setName("create")
	:setDescription("Will create a discord-bot project")
	:setCallback(function(context)
		local targetDirectory = resolveDirectory(context.commandArguments.directory)

		if not targetDirectory then
			error(`Unable to resolve directory: '{context.commandArguments.directory}' - is this a valid path/folder?`)
		end

		Logger:debug(`Resolved path argument as the following directory; '{targetDirectory}'`)

		local information = queryInformation()

		if verifyInformation(information) then
			print("create project!")
		else
			print("exit!")
		end
	end)
	:addArgument({
		name = "directory",
		type = "string",
		required = false,
		description = "The directory to build the project under.",
	})
	:addOption({
		name = "ide",
		type = "string",
		defaultValue = "vscode",
		description = "IDE the project will be setup for",
		valueName = "vscode, nvim",
		aliases = { "i" },
	})
	:addOption({
		name = "runtime",
		type = "string",
		defaultValue = "Lune",
		description = "IDE the project will be setup for",
		valueName = "Lune, Roblox, Zune, Lute",
		aliases = { "r" },
	})
	:build()
