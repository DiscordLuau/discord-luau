local stdFs = require("@std/fs")
local luteTask = require("@std/task")

local io = require("./io")

local fileSystem = {}

function fileSystem.readFile(path: string): string
	return stdFs.readFileToString(path)
end

function fileSystem.writeFile(path: string, contents: string)
	stdFs.writeStringToFile(path, contents)
end

function fileSystem.readDir(path: string): { string }
	local entries = stdFs.listDirectory(path)
	local names = {}

	for _, entry in entries do
		table.insert(names, entry.name)
	end

	return names
end

function fileSystem.readDirEntries(path: string): { { name: string, kind: string } }
	local entries = stdFs.listDirectory(path)
	local result = {}

	for _, entry in entries do
		table.insert(result, {
			name = entry.name,
			kind = if entry.type == "dir" then "directory" else "file",
		})
	end

	return result
end

function fileSystem.stat(path: string): { kind: string, modified: number?, size: number? }
	if not stdFs.exists(path) then
		return { kind = "none", modified = nil, size = nil }
	end

	local meta = stdFs.metadata(path)
	local kind = stdFs.type(path)
	local modified: number? = nil

	if meta and (meta :: any).modified then
		modified = tonumber(tostring((meta :: any).modified))
	end

	local size: number? = nil

	if meta and (meta :: any).size then
		size = tonumber(tostring((meta :: any).size))
	end

	return { kind = if kind == "dir" then "directory" else "file", modified = modified, size = size }
end

function fileSystem.watch(path: string, callback: (path: string, events: { string }) -> ()): { stop: () -> () }
	local stopped = false
	local reportedReadFailure = false
	local snapshots: { [string]: number } = {}

	local function snapshot(): { [string]: number }?
		local ok, entries = pcall(stdFs.listDirectory, path)

		if not ok then
			if not reportedReadFailure then
				reportedReadFailure = true
				io.stderrWrite(`fileSystem.watch: could not read '{path}': {entries}\n`)
			end

			return nil
		end

		reportedReadFailure = false

		local current: { [string]: number } = {}

		for _, entry in entries do
			local entryPath = path .. "/" .. entry.name
			local metadataOk, meta = pcall(stdFs.metadata, entryPath)

			if metadataOk and meta and (meta :: any).modified then
				current[entry.name] = tonumber(tostring((meta :: any).modified)) or 0
			else
				current[entry.name] = 0
			end
		end

		return current
	end

	local function notify(entryPath: string, events: { string })
		luteTask.spawn(function()
			callback(entryPath, events)
		end)
	end

	local initial = snapshot()

	if initial then
		snapshots = initial
	end

	luteTask.spawn(function()
		while not stopped do
			luteTask.wait(1)

			if stopped then
				break
			end

			local current = snapshot()

			if not current then
				continue
			end

			for name, modifiedAt in current do
				local prev = snapshots[name]

				if not prev then
					notify(path .. "/" .. name, { "create" })
				elseif modifiedAt ~= prev then
					notify(path .. "/" .. name, { "change" })
				end
			end

			for name in snapshots do
				if not current[name] then
					notify(path .. "/" .. name, { "remove" })
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

function fileSystem.writeDir(path: string)
	if not stdFs.exists(path) then
		stdFs.createDirectory(path)
	end
end

function fileSystem.removeFile(path: string)
	stdFs.remove(path)
end

function fileSystem.removeDir(path: string)
	stdFs.removeDirectory(path)
end

function fileSystem.isFile(path: string): boolean
	return stdFs.exists(path) and stdFs.type(path) == "file"
end

function fileSystem.isDir(path: string): boolean
	return stdFs.exists(path) and stdFs.type(path) == "dir"
end

return fileSystem
