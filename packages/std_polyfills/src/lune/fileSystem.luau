-- selene: allow(undefined_variable)
local fs = require("@lune/fs")
local task = require("@lune/task")

local fileSystem = {}

function fileSystem.readFile(path: string): string
	return fs.readFile(path)
end

function fileSystem.readDir(path: string): { string }
	return fs.readDir(path)
end

function fileSystem.readDirEntries(path: string): { { name: string, kind: string } }
	local names = fs.readDir(path)
	local result = {}
	for _, name in names do
		local meta = fs.metadata(path .. "/" .. name)
		table.insert(result, { name = name, kind = if meta.kind == "dir" then "directory" else "file" })
	end
	return result
end

function fileSystem.stat(path: string): { kind: string, modified: number?, size: number? }
	local meta = fs.metadata(path)
	local modified = if meta.modifiedAt then meta.modifiedAt.unixTimestamp else nil
	local kind = if meta.kind == "dir" then "directory" else "file"
	return { kind = kind, modified = modified, size = nil }
end

function fileSystem.watch(path: string, callback: (path: string, events: { string }) -> ()): { stop: () -> () }
	local stopped = false
	local snapshots: { [string]: number } = {}

	local function snapshot()
		local ok, entries = pcall(fs.readDir, path)
		if not ok then
			return
		end
		local current: { [string]: number } = {}
		for _, name in entries do
			local entryPath = path .. "/" .. name
			local meta = fs.metadata(entryPath)
			if meta.modifiedAt then
				current[name] = meta.modifiedAt.unixTimestamp
			end
		end
		return current
	end

	local initial = snapshot()
	if initial then
		snapshots = initial
	end

	task.spawn(function()
		while not stopped do
			task.wait(1)
			if stopped then
				break
			end

			local current = snapshot()
			if not current then
				continue
			end

			for name, modifiedAt in current do
				local prev = snapshots[name]
				if prev == nil then
					callback(path .. "/" .. name, { "create" })
				elseif modifiedAt ~= prev then
					callback(path .. "/" .. name, { "change" })
				end
			end

			for name in snapshots do
				if current[name] == nil then
					callback(path .. "/" .. name, { "remove" })
				end
			end

			snapshots = current
		end
	end)

	return {
		stop = function()
			stopped = true
		end,
	}
end

function fileSystem.writeFile(path: string, contents: string)
	return fs.writeFile(path, contents)
end

function fileSystem.writeDir(path: string)
	return fs.writeDir(path)
end

function fileSystem.removeFile(path: string)
	return fs.removeFile(path)
end

function fileSystem.removeDir(path: string)
	return fs.removeDir(path)
end

function fileSystem.isFile(path: string): boolean
	return fs.isFile(path)
end

function fileSystem.isDir(path: string): boolean
	return fs.isDir(path)
end

return fileSystem
