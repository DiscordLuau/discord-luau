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
	end

	error(`Out of reach`)
end

return fileSystem
