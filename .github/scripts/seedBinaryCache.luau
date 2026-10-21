--[[
	Copies the native libraries in this checkout into the cache that `binary.load` reads, so tests load the
	binaries being changed instead of downloading them from a release tag that may not exist yet. `binary.load`
	still checks each file against the checksum in its sys.luau. Run from the repository root:
	zune run .github/scripts/seedBinaryCache.luau
]]

local Logger = require("../../packages/logger/src")
local stdPolyfills = require("../../packages/binary/luau_packages/std_polyfills")

local PACKAGES = { "dave", "opus", "sodium" }

local platform = stdPolyfills.process.getPlatform()
local rawArchitecture = stdPolyfills.process.getArch()
local architecture = if rawArchitecture == "aarch64" then "arm64" elseif rawArchitecture == "x86" then "x86" else "x64"
local extension = if platform == "linux" then ".so" elseif platform == "macos" then ".dylib" else ".dll"
local environment = stdPolyfills.process.getEnv()
local home = environment["HOME"] or environment["USERPROFILE"] or error("neither HOME nor USERPROFILE is set")
local logger = Logger.new("SeedBinaryCache")

local function ensureDirectory(path: string)
	if stdPolyfills.fileSystem.isDir(path) then
		return
	end

	local parent = string.match(path, "^(.*)[/\\][^/\\]+$")

	if parent and parent ~= "" and parent ~= path then
		ensureDirectory(parent)
	end

	stdPolyfills.fileSystem.writeDir(path)
end

for _, package in PACKAGES do
	local source = stdPolyfills.fileSystem.readFile(`packages/{package}/src/sys.luau`)
	local id = string.match(source, 'id = "([^"]+)"') or error(`no binary id in {package}/src/sys.luau`)
	local version = string.match(source, 'version = "([^"]+)"') or error(`no binary version in {package}/src/sys.luau`)
	local urlTemplate = string.match(source, 'url = "([^"]+)"') or error(`no binary url in {package}/src/sys.luau`)
	local filename = string.gsub(string.match(urlTemplate, "[^/]+$") :: string, "{ext}", extension)
	local binaryPath = `packages/{package}/binaries/{platform}-{architecture}/{filename}`
	local cacheDirectory = `{home}/.cache/discord-luau/binaries/{id}/{version}`

	if not stdPolyfills.fileSystem.isFile(binaryPath) then
		logger:info(`skipped {package}: this checkout has no {binaryPath}`)

		continue
	end

	ensureDirectory(cacheDirectory)
	stdPolyfills.fileSystem.writeFile(`{cacheDirectory}/{filename}`, stdPolyfills.fileSystem.readFile(binaryPath))
	logger:info(`seeded {package}: {binaryPath} -> {cacheDirectory}/{filename}`)
end
