--[=[
	@class StdPolyfills.fileSystem
]=]

local runtime = require("./runtime")

local fileSystem = {}

--[=[
	@within StdPolyfills.fileSystem
]=]
function fileSystem.readFile(path: string): string
	local target = runtime.assertRuntime()

	if target == "Lune" then
		return require("./lune/fileSystem").readFile(path)
	elseif target == "Zune" then
		return require("./zune/fileSystem").readFile(path)
	elseif target == "Eryx" then
		return require("./eryx/fileSystem").readFile(path)
	elseif target == "Roblox" then
		error(`fileSystem is not available on Roblox`)
	elseif target == "Lute" then
		error(`Discord-Luau does not currently support the Lute runtime`)
	end

	error(`Out of reach`)
end

--[=[
	@within StdPolyfills.fileSystem
]=]
function fileSystem.readDir(path: string): { string }
	local target = runtime.assertRuntime()

	if target == "Lune" then
		return require("./lune/fileSystem").readDir(path)
	elseif target == "Zune" then
		return require("./zune/fileSystem").readDir(path)
	elseif target == "Eryx" then
		return require("./eryx/fileSystem").readDir(path)
	elseif target == "Roblox" then
		error(`fileSystem is not available on Roblox`)
	elseif target == "Lute" then
		error(`Discord-Luau does not currently support the Lute runtime`)
	end

	error(`Out of reach`)
end

--[=[
	@within StdPolyfills.fileSystem
]=]
function fileSystem.readDirEntries(path: string): { { name: string, kind: string } }
	local target = runtime.assertRuntime()

	if target == "Lune" then
		return require("./lune/fileSystem").readDirEntries(path)
	elseif target == "Zune" then
		return require("./zune/fileSystem").readDirEntries(path)
	elseif target == "Eryx" then
		return require("./eryx/fileSystem").readDirEntries(path)
	elseif target == "Roblox" then
		error(`fileSystem is not available on Roblox`)
	elseif target == "Lute" then
		error(`Discord-Luau does not currently support the Lute runtime`)
	end

	error(`Out of reach`)
end

--[=[
	@within StdPolyfills.fileSystem
]=]
function fileSystem.stat(path: string): { kind: string, modified: number?, size: number? }
	local target = runtime.assertRuntime()

	if target == "Lune" then
		return require("./lune/fileSystem").stat(path)
	elseif target == "Zune" then
		return require("./zune/fileSystem").stat(path)
	elseif target == "Eryx" then
		return require("./eryx/fileSystem").stat(path)
	elseif target == "Roblox" then
		error(`fileSystem is not available on Roblox`)
	elseif target == "Lute" then
		error(`Discord-Luau does not currently support the Lute runtime`)
	end

	error(`Out of reach`)
end

--[=[
	@within StdPolyfills.fileSystem
]=]
function fileSystem.watch(path: string, callback: (path: string, events: { string }) -> ()): { stop: () -> () }
	local target = runtime.assertRuntime()

	if target == "Lune" then
		return require("./lune/fileSystem").watch(path, callback)
	elseif target == "Zune" then
		return require("./zune/fileSystem").watch(path, callback)
	elseif target == "Eryx" then
		return require("./eryx/fileSystem").watch(path, callback)
	elseif target == "Roblox" then
		error(`fileSystem is not available on Roblox`)
	elseif target == "Lute" then
		error(`Discord-Luau does not currently support the Lute runtime`)
	end

	error(`Out of reach`)
end

--[=[
	@within StdPolyfills.fileSystem
]=]
function fileSystem.writeDir(path: string)
	local target = runtime.assertRuntime()

	if target == "Lune" then
		return require("./lune/fileSystem").writeDir(path)
	elseif target == "Zune" then
		return require("./zune/fileSystem").writeDir(path)
	elseif target == "Eryx" then
		return require("./eryx/fileSystem").writeDir(path)
	elseif target == "Roblox" then
		error(`fileSystem is not available on Roblox`)
	elseif target == "Lute" then
		error(`Discord-Luau does not currently support the Lute runtime`)
	end

	error(`Out of reach`)
end

--[=[
	@within StdPolyfills.fileSystem
]=]
function fileSystem.writeFile(path: string, contents: string)
	local target = runtime.assertRuntime()

	if target == "Lune" then
		return require("./lune/fileSystem").writeFile(path, contents)
	elseif target == "Zune" then
		return require("./zune/fileSystem").writeFile(path, contents)
	elseif target == "Eryx" then
		return require("./eryx/fileSystem").writeFile(path, contents)
	elseif target == "Roblox" then
		error(`fileSystem is not available on Roblox`)
	elseif target == "Lute" then
		error(`Discord-Luau does not currently support the Lute runtime`)
	end

	error(`Out of reach`)
end

--[=[
	@within StdPolyfills.fileSystem
]=]
function fileSystem.removeDir(path: string)
	local target = runtime.assertRuntime()

	if target == "Lune" then
		return require("./lune/fileSystem").removeDir(path)
	elseif target == "Zune" then
		return require("./zune/fileSystem").removeDir(path)
	elseif target == "Eryx" then
		return require("./eryx/fileSystem").removeDir(path)
	elseif target == "Roblox" then
		error(`fileSystem is not available on Roblox`)
	elseif target == "Lute" then
		error(`Discord-Luau does not currently support the Lute runtime`)
	end

	error(`Out of reach`)
end

--[=[
	@within StdPolyfills.fileSystem
]=]
function fileSystem.removeFile(path: string)
	local target = runtime.assertRuntime()

	if target == "Lune" then
		return require("./lune/fileSystem").removeFile(path)
	elseif target == "Zune" then
		return require("./zune/fileSystem").removeFile(path)
	elseif target == "Eryx" then
		return require("./eryx/fileSystem").removeFile(path)
	elseif target == "Roblox" then
		error(`fileSystem is not available on Roblox`)
	elseif target == "Lute" then
		error(`Discord-Luau does not currently support the Lute runtime`)
	end

	error(`Out of reach`)
end

--[=[
	@within StdPolyfills.fileSystem
]=]
function fileSystem.isFile(path: string): boolean
	local target = runtime.assertRuntime()

	if target == "Lune" then
		return require("./lune/fileSystem").isFile(path)
	elseif target == "Zune" then
		return require("./zune/fileSystem").isFile(path)
	elseif target == "Eryx" then
		return require("./eryx/fileSystem").isFile(path)
	elseif target == "Roblox" then
		error(`fileSystem is not available on Roblox`)
	elseif target == "Lute" then
		error(`Discord-Luau does not currently support the Lute runtime`)
	end

	error(`Out of reach`)
end

--[=[
	@within StdPolyfills.fileSystem
]=]
function fileSystem.isDir(path: string): boolean
	local target = runtime.assertRuntime()

	if target == "Lune" then
		return require("./lune/fileSystem").isDir(path)
	elseif target == "Zune" then
		return require("./zune/fileSystem").isDir(path)
	elseif target == "Eryx" then
		return require("./eryx/fileSystem").isDir(path)
	elseif target == "Roblox" then
		error(`fileSystem is not available on Roblox`)
	elseif target == "Lute" then
		error(`Discord-Luau does not currently support the Lute runtime`)
	end

	error(`Out of reach`)
end

return fileSystem
