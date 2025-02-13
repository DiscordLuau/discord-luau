local fs = require("@lune/fs")
local process = require("@lune/process")

local packageDir = process.args[1]

local function patchFile(dir, fileName)
	local fileData = fs.readFile(`{dir}/{fileName}`)

	for requirePath: string in fileData.gmatch(fileData, 'local %S+ = require%("(%S+)"%)') do
		if string.sub(requirePath, 1, 1) == "@" then
			print(`{dir}/{fileName}`)
		end
	end
end

local function readFolder(dir)
	for _, object in fs.readDir(dir) do
		if fs.isDir(`{dir}/{object}`) then
			readFolder(`{dir}/{object}`)
		else
			patchFile(dir, object)
		end
	end
end

readFolder(packageDir)
