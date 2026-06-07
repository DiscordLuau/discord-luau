--> Publishes all non-private workspace packages to the pesde registry with rate limit retry handling.

local PACKAGES_DIR = "packages"
local PUBLISH_DELAY = 10
local MAX_RETRIES = 5

local entries = zune.fs.entries(PACKAGES_DIR)
local publishable: { string } = {}

local function isPrivate(packageDirectory: string): boolean
	local manifestPath = `{PACKAGES_DIR}/{packageDirectory}/pesde.toml`
	local success, contents = pcall(zune.fs.readFileSync, manifestPath)

	if not success then
		return true
	end

	local manifest = zune.serde.toml.decode(contents)
	return manifest.private == true
end

local function publishPackage(name: string): boolean
	for attempt = 1, MAX_RETRIES do
		local result = zune.process.run("pesde", { "publish", "--yes" }, {
			stdout = "inherit",
			stderr = "pipe",
			cwd = `{PACKAGES_DIR}/{name}`,
		})

		if result.ok then
			return true
		end

		local stderr = result.stderr or ""

		if string.find(stderr, "package version already exists") then
			print(`[skip] {name} (already published)`)
			return true
		end

		local retryIn = string.match(stderr, "retry in (%d+)s")

		if retryIn then
			local waitTime = tonumber(retryIn) + 1

			print(`[rate limit] retry {attempt}/{MAX_RETRIES} for {name} - waiting {waitTime}s...`)

			zune.task.wait(waitTime)
		else
			if #stderr > 0 then
				print(stderr)
			end

			print(`\n[\27[31merror\27[0m] failed to publish {name} (exit code {result.code})`)
			zune.process.exit(result.code)
		end
	end

	print(`\n[\27[31merror\27[0m] gave up publishing {name} after {MAX_RETRIES} attempts`)
	zune.process.exit(1)
	return false
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

	publishPackage(name)

	local tarball = `{PACKAGES_DIR}/{name}/package.tar.gz`

	local tarballStat = zune.fs.stat(tarball)
	if tarballStat.kind ~= "none" then
		zune.fs.deleteFile(tarball)
	end

	print(`[done] {name}`)
end

print(`\ndone — published {#publishable} package(s)`)
