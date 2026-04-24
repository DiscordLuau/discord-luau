-- selene: allow(undefined_variable)
local fileSystem = {}

function fileSystem.readFile(path: string): string
	return zune.fs.readFile(path)
end

function fileSystem.readDir(path: string): { string }
	local entries = zune.fs.entries(path)
	local names = {}
	for _, entry in entries do
		table.insert(names, entry.name)
	end
	return names
end

function fileSystem.writeFile(path: string, contents: string)
	return zune.fs.writeFile(path, contents)
end

function fileSystem.writeDir(path: string)
	return zune.fs.makeDir(path, true)
end

function fileSystem.removeFile(path: string)
	return zune.fs.deleteFile(path)
end

function fileSystem.removeDir(path: string)
	return zune.fs.deleteDir(path, true)
end

function fileSystem.isFile(path: string): boolean
	local stat = zune.fs.stat(path)
	return stat.kind == "file"
end

function fileSystem.isDir(path: string): boolean
	local stat = zune.fs.stat(path)
	return stat.kind == "directory"
end

return fileSystem
