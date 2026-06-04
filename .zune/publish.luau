--> Publishes all non-private workspace packages to the pesde registry with a 6-second delay between each to avoid rate limiting.

local PACKAGES_DIR = "packages"
local PUBLISH_DELAY = 6

local entries = zune.fs.entries(PACKAGES_DIR)
local publishable: { string } = {}

local function isPrivate(packageDir: string): boolean
	local manifestPath = `{PACKAGES_DIR}/{packageDir}/pesde.toml`
	local success, contents = pcall(zune.fs.readFileSync, manifestPath)

	if not success then
		return true
	end

	local manifest = zune.serde.toml.decode(contents)
	return manifest.private == true
end

for _, entry in entries do
	if entry.kind ~= "directory" then
		continue
	end

	if isPrivate(entry.name) then
		print(`[skip] {entry.name} (private)`)

		continue
	end

	table.insert(publishable, entry.name)
end

print(`publishing {#publishable} package(s)...\n`)

for index, name in publishable do
	if index > 1 then
		print(`[wait] {PUBLISH_DELAY}s...`)

		zune.task.wait(PUBLISH_DELAY)
	end

	print(`[publish] {name}`)

	local result = zune.process.run("pesde", { "publish", "--yes" }, {
		stdout = "inherit",
		stderr = "inherit",
		cwd = `{PACKAGES_DIR}/{name}`,
	})

	if not result.ok then
		print(`\n[\27[31merror\27[0m] failed to publish {name} (exit code {result.code})`)

		zune.process.exit(result.code)
	end

	local tarball = `{PACKAGES_DIR}/{name}/package.tar.gz`
	local tarballStat = zune.fs.stat(tarball)
	if tarballStat.kind ~= "none" then
		zune.fs.deleteFile(tarball)
	end

	print(`[done] {name}`)
end

print(`\ndone — published {#publishable} package(s)`)
