-- selene: allow(undefined_variable)

-- NOTE: we're using the Zune runtime in the CI/CD environment

local requireTests
local requireFile

function requireFile(fullPath: string)
	local path = string.split(fullPath, `/`)
	local fileName = string.match(table.remove(path, #path) :: string, "^(.*)%.spec%.luau$")

	table.remove(path, 1)

	local success, result = pcall(require, `../../{table.concat(path, `/`)}/{fileName}.spec`)

	if not success then
		print(`\n\27[31mFailed to require unit-test at \`{fullPath}\`, error:\27[0m`)
		print(`\27[2m{result}\27[0m`)

		zune.process.exit(1)
	else
		result()
	end
end

function requireTests(path: string)
	for _, entry in zune.fs.entries(path) do
		local entryPath = `{path}/{entry.name}`

		if zune.fs.stat(entryPath).kind == "directory" then
			if entry.name == "luau_packages" or entry.name == "lune_packages" then
				continue
			end

			requireTests(entryPath)
		else
			if not string.find(entry.name, ".spec.luau") then
				continue
			end

			requireFile(entryPath)
		end
	end
end

return requireTests
