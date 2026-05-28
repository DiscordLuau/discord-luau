local fs = require("@eryx/fs")
local task = require("@eryx/task")

local fileSystem = {}

local function readFileRaw(path: string): string
	local file = fs.openSync(path, "r")
	local data = file:read(math.huge)
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
	local stopped = false
	local snapshots: { [string]: number } = {}

	local function snapshot(): { [string]: number }?
		local ok, entries = pcall(fs.listDir, path)
		if not ok then
			return nil
		end
		local current: { [string]: number } = {}
		for _, name in entries do
			local entryPath = path .. "/" .. name
			local ok2, meta = pcall(fs.stat, entryPath)
			if ok2 and meta.mtime then
				current[name] = meta.mtime
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

			for name, mtime in current do
				local prev = snapshots[name]
				if prev == nil then
					callback(path .. "/" .. name, { "create" })
				elseif mtime ~= prev then
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
	local file = fs.openSync(path, "w")
	file:write(contents)
	file:close()
end

function fileSystem.writeDir(path: string)
	fs.mkdir(path, false)
end

function fileSystem.removeFile(path: string)
	fs.remove(path, false)
end

function fileSystem.removeDir(path: string)
	fs.remove(path, true)
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
