local fsWatch = require("@eryx/_fs_watch")
local fs = require("@eryx/fs")

local fileSystem = {}

local function readFileRaw(path: string): string
	local file = fs.openSync(path, "r")
	local data = file:read()
	file:close()

	return data
end

function fileSystem.readFile(path: string): string
	return readFileRaw(path)
end

function fileSystem.readDir(path: string): { string }
	return fs.listDir(path)
end

function fileSystem.readDirEntries(path: string): { { name: string, kind: string } }
	local names = fs.listDir(path)
	local result = {}

	for _, name in names do
		local meta = fs.stat(path .. "/" .. name)
		table.insert(result, { name = name, kind = if meta.isDirectory then "directory" else "file" })
	end

	return result
end

function fileSystem.stat(path: string): { kind: string, modified: number?, size: number? }
	local meta = fs.stat(path)

	return {
		kind = if meta.isDirectory then "directory" else "file",
		modified = meta.mtime,
		size = meta.size,
	}
end

function fileSystem.watch(path: string, callback: (path: string, events: { string }) -> ()): { stop: () -> () }
	local handle = fsWatch.create(path, true, function(eventType: string, filename: string?)
		local fullPath = if filename then path .. "/" .. filename else path

		local events = if eventType == "rename"
			then (if fs.exists(fullPath) then { "create" } else { "remove" })
			else { "change" }

		callback(fullPath, events)
	end)

	return {
		stop = function()
			handle:stop()
		end,
	}
end

function fileSystem.writeFile(path: string, contents: string)
	local file = fs.openSync(path, "w")
	file:write(contents)
	file:close()
end

function fileSystem.writeDir(path: string)
	fs.mkdir(path)
end

function fileSystem.removeFile(path: string)
	fs.remove(path)
end

function fileSystem.removeDir(path: string)
	fs.remove(path)
end

function fileSystem.isFile(path: string): boolean
	if not fs.exists(path) then
		return false
	end

	return fs.stat(path).isFile
end

function fileSystem.isDir(path: string): boolean
	if not fs.exists(path) then
		return false
	end

	return fs.stat(path).isDirectory
end

return fileSystem
