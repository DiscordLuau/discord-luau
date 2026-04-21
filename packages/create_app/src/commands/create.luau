-- selene: allow(undefined_variable)
local CliBuilder = require("../../luau_packages/cli_builder")
local StdPolyfills = require("../../luau_packages/std_polyfills")

local Logger = require("../objects/logger")

local command = CliBuilder.command

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

type VFile = (information: Information) -> string
type VDirectory = { [string]: VDirectory | VFile }

type Information = {
	ProjectName: string,
	IDE: string,
	Runtime: string,
	UseGit: string,
	License: string,
	DiscordToken: string,
}

local function stripBanners(output: string): string
	local lines = {}
	for line in string.gmatch(output .. "\n", "([^\n]*)\n") do
		if not string.match(line, "^[%s]*┃") then
			table.insert(lines, line)
		end
	end
	while #lines > 0 and string.match(lines[#lines], "^%s*$") do
		table.remove(lines)
	end
	return table.concat(lines, "\n")
end

local function processOutput(result: any): string
	local parts = {}
	local cleanStdout = stripBanners(result.stdout or "")
	local cleanStderr = stripBanners(result.stderr or "")
	if #cleanStdout > 0 then
		table.insert(parts, cleanStdout)
	end
	if #cleanStderr > 0 then
		table.insert(parts, cleanStderr)
	end
	return table.concat(parts, "\n")
end

local function resolveDirectory(directory: string?): string?
	if not directory or directory == "." then
		return StdPolyfills.process.getCwd()
	end

	local platform = StdPolyfills.process.getPlatform()
	local separator = OS_SLASH_MAP[platform] or "/"
	local resolvedPath: string

	if string.sub(directory, 1, 1) == "~" then
		local homeVarName = OS_HOME_VARS[platform]
		local home = homeVarName and StdPolyfills.process.getEnv()[homeVarName]

		if not home then
			Logger:error(
				`Unable to resolve {OS_HOME_VARS[platform]} environment variable! Does this environment variable exist?`
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

local function buildProjectMap(projectMap: VDirectory, path: string, information: Information)
	for key, value in projectMap do
		if typeof(value) == "table" then
			StdPolyfills.fileSystem.writeDir(`{path}/{key}`)
			buildProjectMap(value :: VDirectory, `{path}/{key}`, information)
		else
			StdPolyfills.fileSystem.writeFile(`{path}/{key}`, (value :: VFile)(information))
		end
	end
end

local function setupProject(path: string, projectFile: string, information: Information)
	local directoryName = string.match(information.ProjectName, "[^/]+$") or information.ProjectName

	if StdPolyfills.fileSystem.isDir(`{path}/{directoryName}`) then
		return Logger:error(`Directory '{path}/{directoryName}' already exists - aborting project creation!`)
	end

	if StdPolyfills.fileSystem.isFile(`{path}/{directoryName}`) then
		return Logger:error(
			`Directory '{path}/{directoryName}' already exists (as a file) - aborting project creation!`
		)
	end

	StdPolyfills.fileSystem.writeDir(`{path}/{directoryName}`)

	local projectMap: VDirectory = (require :: any)(`./../projects/{projectFile}`)

	buildProjectMap(projectMap, `{path}/{directoryName}`, information)

	Logger:debug(`Finished setting up project in the following dir: '{`{path}/{directoryName}`}'`)
end

return command
	.new()
	:setName("create")
	:setDescription("Scaffold a new Discord bot project in Luau")
	:setCallback(function(context)
		local currentRuntime = StdPolyfills.runtime.getRuntime()

		if currentRuntime ~= "Zune" then
			Logger:error(
				`create_app must be run with the Zune runtime (detected: '{currentRuntime}'). `
					.. `Please run this tool via 'pesde x discord_luau/create_app', which will invoke Zune automatically.`
			)

			return
		end

		local targetDirectory = resolveDirectory(context.commandArguments.directory)

		if not targetDirectory then
			error(`Unable to resolve directory: '{context.commandArguments.directory}' - is this a valid path/folder?`)
		end

		Logger:debug(`Resolved path argument as the following directory; '{targetDirectory}'`)

		require("../ui/createWizard")(function(info, setStatus, _setWarning)
			local projectDirectoryName = string.match(info.ProjectName, "[^/]+$") or info.ProjectName
			local projectPath = `{targetDirectory}/{projectDirectoryName}`

			setStatus("Creating project structure…", 0.10)
			setupProject(targetDirectory, info.IDE, info)

			setStatus("Running rokit install…", 0.35)
			local rokitResult = zune.process.run("rokit", { "install" }, { cwd = projectPath })

			if not rokitResult.ok then
				local output = processOutput(rokitResult)
				error(`rokit install failed (exit {rokitResult.code}){if #output > 0 then "\n" .. output else ""}`)
			end

			setStatus("Running lune setup…", 0.55)
			local luneSetupResult = zune.process.run("lune", { "setup" }, { cwd = projectPath })

			if not luneSetupResult.ok then
				local output = processOutput(luneSetupResult)
				error(`lune setup failed (exit {luneSetupResult.code}){if #output > 0 then "\n" .. output else ""}`)
			end

			if info.UseGit == "Yes" then
				setStatus("Running git init…", 0.65)
				local gitInitResult = zune.process.run("git", { "init" }, { cwd = projectPath })

				if not gitInitResult.ok then
					local output = processOutput(gitInitResult)
					error(`git init failed (exit {gitInitResult.code}){if #output > 0 then "\n" .. output else ""}`)
				end
			end

			setStatus("Running pesde install…", 0.80)
			local pesdeResult = zune.process.run("pesde", { "install" }, { cwd = projectPath })

			if not pesdeResult.ok then
				local output = processOutput(pesdeResult)
				error(`pesde install failed (exit {pesdeResult.code}){if #output > 0 then "\n" .. output else ""}`)
			end

			return projectPath
		end)
	end)
	:addArgument({
		name = "directory",
		type = "string",
		required = false,
		description = "The directory to build the project under.",
	})
	:build()
