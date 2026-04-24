local luaTableSource = "{\n"
local packageDir = zune.process.args[2]

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
	for _, entry in zune.fs.entries(dir) do
		local entryPath = `{dir}/{entry.name}`

		if zune.fs.stat(entryPath).kind == "directory" then
			openFolder(entryPath)
			readFolder(entryPath)
			closeFolder()
		else
			readFile(dir, entry.name)
		end
	end
end

readFolder(packageDir)

luaTableSource ..= "}\n"

print(luaTableSource)
