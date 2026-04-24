-- selene: allow(undefined_variable)
local zuneFs = zune.fs

local fileSystem = {}

function fileSystem.readFile(path: string): string
	return zuneFs.readFile(path)
end

function fileSystem.readDir(path: string): { string }
	local entries = zuneFs.entries(path)
	local names = {}
	for _, entry in entries do
		table.insert(names, entry.name)
	end
	return names
end

function fileSystem.writeFile(path: string, contents: string)
	return zuneFs.writeFile(path, contents)
end

function fileSystem.writeDir(path: string)
	return zuneFs.makeDir(path, true)
end

function fileSystem.removeFile(path: string)
	return zuneFs.deleteFile(path)
end

function fileSystem.removeDir(path: string)
	return zuneFs.deleteDir(path, true)
end

function fileSystem.isFile(path: string): boolean
	local stat = zuneFs.stat(path)
	return stat.kind == "file"
end

function fileSystem.isDir(path: string): boolean
	local stat = zuneFs.stat(path)
	return stat.kind == "directory"
end

return fileSystem
