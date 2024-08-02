--[[
	Responsible for requiring all descendants of the 'tests' directory, and then calling those test functions
		by calling these test functions, we're able to run all unit tests.
]]

-- WARNING: we're using the `Lune` runtime in the CI/CD environment, so we're not going to be using the `@std-polyfills`
-- package that the discord-luau package uses.

local fs = require("@lune/fs")
local stdio = require("@lune/stdio")
local process = require("@lune/process")

local requireTests
local requireFile

function requireFile(fullPath: string)
	local success, result = pcall(require, fullPath)

	if not success then
		print(`{stdio.color("red")}Failed to require the following Unit Test; {fullPath}, please fix the error below;`)
		print(`{stdio.color("cyan")}{result}`)

		process.exit(1)
	else
		result()
	end
end

function requireTests(path: string)
	for _, object in fs.readDir(path) do
		if fs.isDir(`{path}/{object}`) then
			requireTests(`{path}/{object}`)
		else
			requireFile(`{path}/{object}`)
		end
	end
end

return requireTests
