--> Runs tests located in the tests/ directory

-- NOTE: we're using the `Lune` runtime in the CI/CD environment, so we're not going to be using the `@std-polyfills`
-- package that the discord-luau package uses.

local fs = require("@lune/fs")
local stdio = require("@lune/stdio")
local process = require("@lune/process")

local requireTests
local requireFile

function requireFile(fullPath: string)
	local success, result = pcall(require, fullPath)

	if not success then
		print(`\n{stdio.color("red")}Failed to require unit-test at \`{fullPath}\`, error:`)
		print(`{stdio.style("dim")}{result}`)

		process.exit(1)
	else
		result()
	end
end

function requireTests(path: string)
	for _, object in fs.readDir(path) do
		if fs.isDir(`{path}/{object}`) then
			if object == "luau_packages" or object == "lune_packages" then
				continue
			end

			requireTests(`{path}/{object}`)
		else
			if not string.find(object, ".spec.luau") then
				continue
			end

			requireFile(`{path}/{object}`)
		end
	end
end

return requireTests
