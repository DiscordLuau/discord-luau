local frktest = require("../../../luau_packages/frktest")
local stdPolyfills = require("../luau_packages/std_polyfills")

local binary = require("../src")
local sha256 = require("../src/sha256")

local SCRATCH_DIRECTORY = "packages/binary/tests/allowSystemScratch"
local LIBRARY_ID = "discordluaufakesystemlibrary"
local VERSION = "0.0.0"
local CACHED_CONTENT = "the checksummed cache file"
local SYSTEM_CONTENT = "the fake system copy"

local test = frktest.test
local check = frktest.assert.check

local platform = stdPolyfills.process.getPlatform()
local extension = if platform == "linux" then ".so" elseif platform == "macos" then ".dylib" else ".dll"
local libraryPathName = if platform == "linux"
	then "LD_LIBRARY_PATH"
	elseif platform == "macos" then "DYLD_LIBRARY_PATH"
	else "PATH"

local function withFakeSystemCopy(body: (options: binary.LoadOptions, cachePath: string, systemPath: string) -> ())
	local systemDirectory = `{SCRATCH_DIRECTORY}/system`
	local homeDirectory = `{SCRATCH_DIRECTORY}/home`
	local cachePath = `{homeDirectory}/.cache/discord-luau/binaries/{LIBRARY_ID}/{VERSION}/{LIBRARY_ID}{extension}`
	local systemPath = `{systemDirectory}/{LIBRARY_ID}{extension}`
	local originalGetEnv = stdPolyfills.process.getEnv

	stdPolyfills.fileSystem.writeDir(systemDirectory)
	stdPolyfills.fileSystem.writeDir(`{homeDirectory}/.cache/discord-luau/binaries/{LIBRARY_ID}/{VERSION}`)
	stdPolyfills.fileSystem.writeFile(systemPath, SYSTEM_CONTENT)
	stdPolyfills.fileSystem.writeFile(cachePath, CACHED_CONTENT)

	local options: binary.LoadOptions = {
		id = LIBRARY_ID,
		version = VERSION,
		url = "https://invalid.invalid/" .. LIBRARY_ID .. "{ext}",
		checksum = `sha256:{sha256.new():update(CACHED_CONTENT):hex()}`,
	}
	local ran, failure = pcall(function()
		stdPolyfills.process.getEnv = function()
			local environment = table.clone(originalGetEnv())

			environment["HOME"] = homeDirectory
			environment["USERPROFILE"] = homeDirectory
			environment[libraryPathName] = systemDirectory

			return environment
		end

		body(options, cachePath, systemPath)
	end)

	stdPolyfills.process.getEnv = originalGetEnv
	stdPolyfills.fileSystem.removeDir(SCRATCH_DIRECTORY)

	if not ran then
		error(failure, 0)
	end
end

return function()
	test.suite("binary allowSystem", function()
		test.case("allowSystem = false skips the system copy and loads the checksummed cache file", function()
			withFakeSystemCopy(function(options, cachePath)
				options.allowSystem = false

				check.equal(binary.load(options).path, cachePath)
			end)
		end)

		test.case("the default still prefers the system copy", function()
			withFakeSystemCopy(function(options, _, systemPath)
				check.equal(binary.load(options).path, systemPath)
			end)
		end)

		test.case("allowSystem = true prefers the system copy", function()
			withFakeSystemCopy(function(options, _, systemPath)
				options.allowSystem = true

				check.equal(binary.load(options).path, systemPath)
			end)
		end)
	end)
end
