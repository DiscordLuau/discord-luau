--[=[
	@class Commands.Loader
	@__index Prototype

	Loads command modules from a directory tree and supports hot-reload via file watching.
]=]

--[=[
	@prop registry registry.Registry
	@within Commands.Loader
]=]

--[=[
	@prop logger logger.Logger
	@within Commands.Loader
]=]

--[=[
	@prop context any
	@within Commands.Loader
]=]

local logger = require("../luau_packages/logger")
local stdPolyfills = require("../luau_packages/std_polyfills")

local registry = require("@self/registry")

-- debug.info(1, "s") returns the path of this source file, which we use to
-- compute how many directory levels separate the loader from the project root.
-- That depth determines the `../` prefix we must prepend to user-supplied paths
-- so that require() resolves them relative to the project root, not to this file.
local SOURCE = debug.info(1, "s")

local Loader = {}

Loader.Interface = {}
Loader.Prototype = {}

local function computeRequirePrefix(): string
	local sourcePath = SOURCE

	if string.sub(sourcePath, 1, 1) == "/" then
		local cwd = stdPolyfills.process.getCwd()

		if string.sub(sourcePath, 1, #cwd) == cwd then
			sourcePath = string.sub(sourcePath, #cwd + 2)
		end
	end

	local directory = string.match(sourcePath, "^(.*)/[^/]+$") or ""
	local depth = select(2, string.gsub(directory, "[^/]+", ""))

	return string.rep("../", depth)
end

local function normalizePath(path: string): string
	return string.match(path, "^%.%/(.+)") or path
end

local function stripExtension(filename: string): string
	return string.match(filename, "^(.+)%.luau$") or filename
end

local function getFileName(path: string): string
	return string.match(path, "([^/\\]+)$") or path
end

local function generateTemporaryId(): string
	return string.format(
		"%x%x%x%x",
		math.random(0, 0xFFFF),
		math.random(0, 0xFFFF),
		math.random(0, 0xFFFF),
		math.random(0, 0xFFFF)
	)
end

local function isValidCommandDefinition(value: any): boolean
	if type(value) ~= "table" then
		return false
	end

	if type(value.command) ~= "table" or type(value.command.name) ~= "string" then
		return false
	end

	if type(value.execute) ~= "function" then
		return false
	end

	return true
end

local function resolveModule(rawModule: any, context: any): (boolean, any)
	if type(rawModule) == "function" then
		return pcall(rawModule :: (any) -> any, context)
	end

	return true, rawModule
end

--[=[
	@within Commands.Loader

	Recursively loads all .luau command modules found under `directoryPath`.
]=]
function Loader.Prototype.load(self: Loader, directoryPath: string)
	local entries = stdPolyfills.fileSystem.readDirEntries(directoryPath)

	local normalizedDirectory = normalizePath(directoryPath)

	for _, directoryEntry in entries do
		if directoryEntry.kind == "directory" then
			self:load(directoryPath .. "/" .. directoryEntry.name)
			continue
		end

		if directoryEntry.kind ~= "file" then
			continue
		end

		if not string.match(directoryEntry.name, "%.luau$") then
			continue
		end

		local moduleName = stripExtension(directoryEntry.name)

		local requireSuccess, rawModule =
			pcall(require, computeRequirePrefix() .. normalizedDirectory .. "/" .. moduleName)

		if not requireSuccess then
			self.logger:warn(`failed to load '{directoryEntry.name}': {rawModule}`)
			continue
		end

		local resolveSuccess, loadedModule = resolveModule(rawModule, self.context)

		if not resolveSuccess then
			self.logger:warn(`factory for '{directoryEntry.name}' threw: {loadedModule}`)
			continue
		end

		if not isValidCommandDefinition(loadedModule) then
			self.logger:warn(`'{directoryEntry.name}' skipped: missing .command.name or .execute`)
			continue
		end

		self.logger:debug(`loaded command '{loadedModule.command.name}'`)

		self.registry:set(loadedModule)
	end
end

--[=[
	@within Commands.Loader

	Re-requires a command file by writing its content to a temp file, bypassing the module cache.
	The temporary file is deleted immediately after the require call.
]=]
function Loader.Prototype.reload(self: Loader, directoryPath: string, name: string)
	local filePath = directoryPath .. "/" .. name .. ".luau"
	local readSuccess, fileContent = pcall(stdPolyfills.fileSystem.readFile, filePath)

	if not readSuccess then
		self.logger:warn(`failed to read '{name}' for reload: {fileContent}`)
		return
	end

	local temporaryName = name .. "." .. generateTemporaryId()
	local temporaryPath = directoryPath .. "/" .. temporaryName .. ".luau"

	stdPolyfills.fileSystem.writeFile(temporaryPath, fileContent)

	local normalizedDirectory = normalizePath(directoryPath)
	local requireSuccess, rawModule =
		pcall(require, computeRequirePrefix() .. normalizedDirectory .. "/" .. temporaryName)

	stdPolyfills.fileSystem.removeFile(temporaryPath)

	if not requireSuccess then
		self.logger:warn(`failed to reload '{name}': {rawModule}`)
		return
	end

	local resolveSuccess, loadedModule = resolveModule(rawModule, self.context)

	if not resolveSuccess then
		self.logger:warn(`factory for '{name}' threw on reload: {loadedModule}`)
		return
	end

	if not isValidCommandDefinition(loadedModule) then
		self.logger:warn(`'{name}' reload skipped: invalid CommandDefinition shape`)
		return
	end

	self.logger:info(`reloaded command '{loadedModule.command.name}'`)

	self.registry:set(loadedModule)
end

--[=[
	@within Commands.Loader

	Watches `directoryPath` recursively for file changes, reloading or unloading commands as needed.
	Returns a stop function that cancels all watchers.
]=]
function Loader.Prototype.watch(self: Loader, directoryPath: string): () -> ()
	local stoppers: { () -> () } = {}

	local function watchDirectory(directory: string)
		local watcher = stdPolyfills.fileSystem.watch(directory, function(path: string, events: { string })
			local eventName = events[1]
			local fileName = getFileName(path)

			if not string.match(fileName, "%.luau$") then
				return
			end

			-- Ignore the temporary files we write during hot-reload.
			if string.match(fileName, "%.[%x][%x][%x][%x][%x][%x][%x][%x]+%.luau$") then
				return
			end

			local moduleName = stripExtension(fileName)

			if eventName == "write" or eventName == "change" then
				self:reload(directory, moduleName)
			elseif eventName == "create" then
				local normalizedDirectory = normalizePath(directory)

				local requireSuccess, rawModule =
					pcall(require, computeRequirePrefix() .. normalizedDirectory .. "/" .. moduleName)

				if requireSuccess then
					local resolveSuccess, loadedModule = resolveModule(rawModule, self.context)

					if resolveSuccess and isValidCommandDefinition(loadedModule) then
						self.logger:info(`loaded new command '{loadedModule.command.name}'`)

						self.registry:set(loadedModule)
					end
				end
			elseif eventName == "remove" or eventName == "rename" then
				self.logger:info(`unloaded command '{moduleName}'`)
				self.registry:remove(moduleName)
			end
		end)

		table.insert(stoppers, function()
			watcher.stop()
		end)
	end

	local function setupWatchers(directory: string)
		watchDirectory(directory)

		local success, entries = pcall(stdPolyfills.fileSystem.readDirEntries, directory)

		if not success then
			self.logger:warn(`failed to read directory '{directory}' during watch setup`)
			return
		end

		for _, entry in entries do
			if entry.kind == "directory" then
				setupWatchers(directory .. "/" .. entry.name)
			end
		end
	end

	setupWatchers(directoryPath)

	return function()
		for _, stop in stoppers do
			stop()
		end
	end
end

--[=[
	@within Commands.Loader

	Constructs a new loader bound to the given registry, logger, and optional context object.
]=]
function Loader.Interface.new(registryInstance: registry.Registry, loggerInstance: logger.Logger, context: any): Loader
	return setmetatable(
		{
			registry = registryInstance,
			logger = loggerInstance,
			context = context,
		} :: Loader,
		{ __index = Loader.Prototype }
	)
end

export type Loader = typeof(Loader.Prototype) & {
	registry: registry.Registry,
	logger: logger.Logger,
	context: any,
}

return Loader.Interface
