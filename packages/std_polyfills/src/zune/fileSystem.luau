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

function fileSystem.readDirEntries(path: string): { { name: string, kind: string } }
	local entries = zune.fs.entries(path)
	local result = {}
	for _, entry in entries do
		table.insert(result, { name = entry.name, kind = entry.kind })
	end
	return result :: any
end

function fileSystem.stat(path: string): { kind: string, modified: number?, size: number? }
	local meta = zune.fs.stat(path)
	if meta.kind == "none" then
		return { kind = "none", modified = nil, size = nil }
	end
	return {
		kind = (meta :: any).kind,
		modified = (meta :: any).modified_at,
		size = (meta :: any).size,
	}
end

function fileSystem.watch(path: string, callback: (path: string, events: { string }) -> ()): { stop: () -> () }
	local EVENT_MAP: { [string]: string } = {
		modified = "change",
		created = "create",
		deleted = "remove",
		renamed = "rename",
	}
	local watcher = zune.fs.watch(path, function(watchPath: string, watchEvents)
		local translated = {}

		for _, event in watchEvents do
			table.insert(translated, EVENT_MAP[event] or event)
		end

		callback(watchPath, translated)
	end)
	return {
		stop = function()
			watcher:stop()
		end,
	}
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
