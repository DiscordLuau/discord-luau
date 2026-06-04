--[=[
	@class Binary
]=]

local sha256 = require("@self/../luau_packages/sha256")
local stdPolyfills = require("@self/../luau_packages/std_polyfills")

local Binary = {}

local function resolveTokens(url: string, version: string): string
	local platform = stdPolyfills.process.getPlatform()
	local rawArchitecture = stdPolyfills.process.getArch()

	local architecture = if rawArchitecture == "aarch64" then "arm64" elseif rawArchitecture == "x86" then "x86" else "x64"
	local extension = if platform == "linux" then ".so" elseif platform == "macos" then ".dylib" else ".dll"

	local resolved = string.gsub(url, "{version}", version)

	resolved = string.gsub(resolved, "{os}", platform)
	resolved = string.gsub(resolved, "{arch}", architecture)
	resolved = string.gsub(resolved, "{ext}", extension)

	return resolved
end

local function filenameFromUrl(url: string): string
	return string.match(url, "[^/]+$") or error(`Cannot extract filename from URL: {url}`)
end

local function getCacheDir(id: string, version: string): string
	local environment = stdPolyfills.process.getEnv()

	local home = environment["HOME"] or environment["USERPROFILE"]

	if not home then
		error("Cannot determine home directory: neither HOME nor USERPROFILE is set")
	end

	return `{home}/.cache/discord-luau/binaries/{id}/{version}`
end

local function ensureDir(path: string)
	if stdPolyfills.fileSystem.isDir(path) then
		return
	end

	local parent = string.match(path, "^(.*)[/\\][^/\\]+$")

	if parent and parent ~= "" and parent ~= path then
		ensureDir(parent)
	end

	stdPolyfills.fileSystem.writeDir(path)
end

local function verifySha256(content: string, expectedChecksum: string): boolean
	local algorithm, expected = string.match(expectedChecksum, "^([^:]+):(.+)$")

	if algorithm ~= "sha256" then
		error(`Unsupported checksum algorithm: '{algorithm}' (only 'sha256' is supported)`)
	end

	local actual = sha256.new():update(content):hex()

	return actual == expected
end

local function probeSystemPaths(id: string): string?
	local platform = stdPolyfills.process.getPlatform()
	local extension = if platform == "linux" then ".so" elseif platform == "macos" then ".dylib" else ".dll"
	local libraryFilename = `{id}{extension}`
	local environment = stdPolyfills.process.getEnv()
	local paths: { string } = {}

	if platform == "linux" then
		local ldLibraryPath = environment["LD_LIBRARY_PATH"]

		if ldLibraryPath then
			for directory in string.gmatch(ldLibraryPath, "[^:]+") do
				table.insert(paths, directory)
			end
		end

		table.insert(paths, "/usr/lib")
		table.insert(paths, "/usr/local/lib")
		table.insert(paths, "/usr/lib/x86_64-linux-gnu")
		table.insert(paths, "/usr/lib/aarch64-linux-gnu")
	elseif platform == "macos" then
		local dyldLibraryPath = environment["DYLD_LIBRARY_PATH"]

		if dyldLibraryPath then
			for directory in string.gmatch(dyldLibraryPath, "[^:]+") do
				table.insert(paths, directory)
			end
		end

		table.insert(paths, "/usr/lib")
		table.insert(paths, "/usr/local/lib")
		table.insert(paths, "/opt/homebrew/lib")
	elseif platform == "windows" then
		local pathEnvironment = environment["PATH"]

		if pathEnvironment then
			for directory in string.gmatch(pathEnvironment, "[^;]+") do
				table.insert(paths, directory)
			end
		end

		table.insert(paths, "C:/Windows/System32")
	end

	for _, directory in ipairs(paths) do
		local candidate = `{directory}/{libraryFilename}`

		if stdPolyfills.fileSystem.isFile(candidate) then
			return candidate
		end
	end

	return
end

--[=[
	@within Binary

	Resolves a native shared library by searching system paths, then the local
	cache, then downloading from the provided URL.

	The URL template supports `{version}`, `{os}`, `{arch}`, and `{ext}` tokens.
	`{os}` is `linux`, `macos`, or `windows`. `{arch}` is `x64` or `arm64`.
	`{ext}` is `.so`, `.dylib`, or `.dll` (includes leading dot).

	The checksum must be in `sha256:<hex>` format.
]=]
function Binary.load(options: LoadOptions): LoadResult
	local resolvedUrl = resolveTokens(options.url, options.version)
	local filename = filenameFromUrl(resolvedUrl)
	local cacheDir = getCacheDir(options.id, options.version)
	local cachePath = `{cacheDir}/{filename}`

	local systemPath = probeSystemPaths(options.id)

	if systemPath then
		return { path = systemPath }
	end

	if stdPolyfills.fileSystem.isFile(cachePath) then
		local content = stdPolyfills.fileSystem.readFile(cachePath)

		if verifySha256(content, options.checksum) then
			return { path = cachePath }
		end
	end

	local response = stdPolyfills.net.request({
		url = resolvedUrl,
		method = "GET",
	})

	if not response.ok then
		error(
			`Failed to download '{options.id}' from {resolvedUrl}: HTTP {response.statusCode} {response.statusMessage}`
		)
	end

	if not verifySha256(response.body, options.checksum) then
		error(`Checksum mismatch for '{filename}': expected {options.checksum}`)
	end

	ensureDir(cacheDir)

	stdPolyfills.fileSystem.writeFile(cachePath, response.body)

	return { path = cachePath }
end

export type LoadOptions = {
	id: string,
	version: string,
	url: string,
	checksum: string,
}

export type LoadResult = {
	path: string,
}

return Binary
