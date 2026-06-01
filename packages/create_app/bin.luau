local process = require("@lune/process")

local zuneFound, zuneResult = pcall(process.exec, "zune", { "--version" })

if not zuneFound or not zuneResult.ok then
	print(
		"[ERROR] zune is not installed or not found in PATH. "
			.. "Install via rokit: https://github.com/Scythe-Technology/zune"
	)
	process.exit(1)
end

local scriptSource: string = debug.info(1, "s")
local packageDirectory: string = string.match(scriptSource, "^(.*)[/\\][^/\\]+$") or "."

local entryPoint = packageDirectory .. "/src/init.luau"
local osInfo = process.os

local spawnArgs: { string } = { "run", entryPoint }

for _, argument in process.args do
	table.insert(spawnArgs, argument)
end

if osInfo == "windows" then
	local needsConsole = false

	for _, argument in process.args do
		if argument == "create" then
			needsConsole = true
			break
		end
	end

	if needsConsole then
		local extraArguments = ""

		for _, argument in process.args do
			extraArguments = extraArguments
				.. (if string.find(argument, " ", 1, true) then ' "' .. argument .. '"' else " " .. argument)
		end

		local innerCommand = "zune run src/init.luau" .. extraArguments .. " & pause"
		local env = table.clone(process.env)

		env.DISCORD_LUAU_CWD = process.cwd

		process.exec(
			"cmd",
			{ "/c", "start", "/wait", "cmd", "/c", innerCommand },
			{ cwd = packageDirectory, stdio = "forward", env = env }
		)
	else
		process.exec("zune", spawnArgs, { stdio = "forward" })
	end
else
	local quotedArguments = {}

	for _, argument in spawnArgs do
		table.insert(quotedArguments, "'" .. string.gsub(argument, "'", "'\\''") .. "'")
	end

	local commandString = "zune " .. table.concat(quotedArguments, " ") .. " < /dev/tty > /dev/tty"

	process.exec("sh", { "-c", commandString }, {
		stdio = "forward",
	})
end
