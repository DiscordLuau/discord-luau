--[[
	Publishes every non-private package under packages/ to the pesde registry, each one after the packages it
	depends on, retrying when the registry rate-limits and skipping versions it already holds. Run from the
	repository root after `pesde auth login`; --dry-run prints the order and publishes nothing:
	zune run .zune/publish.luau [--dry-run]
]]

local Logger = require("../packages/logger/src")

local PACKAGES_DIRECTORY = "packages"
local PUBLISH_DELAY_SECONDS = 10
local MAX_ATTEMPTS = 5
local SCOPE = "discord_luau/"

local isDryRun = if table.find(zune.process.args, "--dry-run") then true else false
local logger = Logger.new("Publish")
local directories: { [string]: string } = {}
local dependenciesOf: { [string]: { string } } = {}

local function scopedDependencies(manifest: { [string]: any }): { string }
	local dependencies: { string } = {}

	for _, section in { "dependencies", "peer_dependencies" } do
		for _, specifier in manifest[section] or {} do
			local target = specifier.workspace or specifier.name

			if target and string.sub(target, 1, #SCOPE) == SCOPE then
				table.insert(dependencies, target)
			end
		end
	end

	return dependencies
end

local function publishOrder(): { string }
	local ordered: { string } = {}
	local visited: { [string]: "visiting" | "done" } = {}
	local names: { string } = {}

	local function visit(name: string)
		visited[name] = "visiting"

		for _, dependency in dependenciesOf[name] do
			assert(visited[dependency] ~= "visiting", `dependency cycle through {dependency}`)

			if dependenciesOf[dependency] and not visited[dependency] then
				visit(dependency)
			end
		end

		visited[name] = "done"
		table.insert(ordered, directories[name])
	end

	for name in dependenciesOf do
		table.insert(names, name)
	end

	table.sort(names)

	for _, name in names do
		if not visited[name] then
			visit(name)
		end
	end

	return ordered
end

local function publishPackage(directory: string)
	for attempt = 1, MAX_ATTEMPTS do
		local result = zune.process.run("pesde", { "publish", "--yes" }, {
			stdout = "inherit",
			stderr = "pipe",
			cwd = `{PACKAGES_DIRECTORY}/{directory}`,
		})
		local stderr = result.stderr or ""
		local retrySeconds = tonumber(string.match(stderr, "retry in (%d+)s"))

		if result.ok then
			logger:info(`published {directory}`)

			return
		end

		if string.find(stderr, "package version already exists") then
			logger:info(`skipped {directory}: this version is already published`)

			return
		end

		if retrySeconds then
			logger:info(
				`rate limited publishing {directory} (attempt {attempt} of {MAX_ATTEMPTS}), retrying in {retrySeconds + 1}s`
			)
			zune.task.wait(retrySeconds + 1)
		else
			logger:warn(`could not publish {directory} (exit code {result.code}): {stderr}`)
			zune.process.exit(result.code)
		end
	end

	logger:warn(`gave up publishing {directory} after {MAX_ATTEMPTS} attempts`)
	zune.process.exit(1)
end

local function publishAll()
	local order = publishOrder()

	logger:info(`{#order} package(s) in publish order: {table.concat(order, ", ")}`)

	if isDryRun then
		logger:info("dry run: nothing published")

		return
	end

	for index, directory in order do
		local tarball = `{PACKAGES_DIRECTORY}/{directory}/package.tar.gz`

		if index > 1 then
			logger:info(`waiting {PUBLISH_DELAY_SECONDS}s before {directory}`)
			zune.task.wait(PUBLISH_DELAY_SECONDS)
		end

		publishPackage(directory)

		if zune.fs.stat(tarball).kind ~= "none" then
			zune.fs.deleteFile(tarball)
		end
	end

	logger:info(`done: {#order} package(s) published or already up to date`)
end

for _, entry in zune.fs.entries(PACKAGES_DIRECTORY) do
	local manifestPath = `{PACKAGES_DIRECTORY}/{entry.name}/pesde.toml`

	if entry.kind ~= "directory" or zune.fs.stat(manifestPath).kind == "none" then
		logger:debug(`skipped {entry.name}: not a package`)

		continue
	end

	local manifest = zune.serde.toml.decode(zune.fs.readFileSync(manifestPath))

	if manifest.private then
		logger:info(`skipped {entry.name}: private`)

		continue
	end

	directories[manifest.name] = entry.name
	dependenciesOf[manifest.name] = scopedDependencies(manifest)
end

publishAll()
