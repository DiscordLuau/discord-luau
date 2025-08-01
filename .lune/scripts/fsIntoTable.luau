local fs = require("@lune/fs")
local process = require("@lune/process")

local luaTableSource = "{\n"
local packageDir = process.args[1]

local function readFile(dir, fileName)
	local fileName = string.sub(fileName, 1, -6)
	local source = `{dir}/{fileName}`

	luaTableSource = `local {fileName} = require("{string.gsub(source, packageDir .. "/", "")}")\n` .. luaTableSource
	luaTableSource ..= `{fileName} = {fileName},\n`
end

local function openFolder(dir)
	local dirSplit = string.split(dir, "/")
	local dirName = dirSplit[#dirSplit]

	luaTableSource ..= `{dirName} = \{\n`
end

local function closeFolder()
	luaTableSource ..= `},\n`
end

local function readFolder(dir)
	for _, object in fs.readDir(dir) do
		if fs.isDir(`{dir}/{object}`) then
			openFolder(`{dir}/{object}`)
			readFolder(`{dir}/{object}`)
			closeFolder()
		else
			readFile(dir, object)
		end
	end
end

readFolder(packageDir)

luaTableSource ..= "}\n"

print(luaTableSource)
