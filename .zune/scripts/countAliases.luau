local packageDir = zune.process.args[2]

local function patchFile(dir, fileName)
	local fileData = zune.fs.readFile(`{dir}/{fileName}`)

	for requirePath: string in fileData.gmatch(fileData, 'local %S+ = require%("(%S+)"%)') do
		if string.sub(requirePath, 1, 1) == "@" then
			print(`{dir}/{fileName}`)
		end
	end
end

local function readFolder(dir)
	for _, entry in zune.fs.entries(dir) do
		local entryPath = `{dir}/{entry.name}`

		if zune.fs.stat(entryPath).kind == "directory" then
			readFolder(entryPath)
		else
			patchFile(dir, entry.name)
		end
	end
end

readFolder(packageDir)
