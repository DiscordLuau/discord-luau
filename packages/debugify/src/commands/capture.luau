local CliBuilder = require("../../luau_packages/cli_builder")
local StdPolyfills = require("../../luau_packages/std_polyfills")
local diagnostics = require("../utilities/diagnostics")
local redact = require("../utilities/redact")

local command = CliBuilder.command

local ESC = "\x1b"
local LOG_MAX = 200
local LINE_WIDTH = 80

local function rule(char: string?): string
	return string.rep(char or "=", LINE_WIDTH)
end

local function logField(key: string, value: string, keyWidth: number?): string
	local padding = string.rep(" ", (keyWidth or 14) - #key)
	return `  {key}{padding}{value}`
end

local function buildLogHeader(diagnosticsInfo: diagnostics.DiagnosticsInfo, script: string, runtime: string): string
	local lines = {
		rule(),
		"  discord-luau debuggify — capture log",
		rule(),
		logField("started", os.date("!%Y-%m-%d %H:%M:%S UTC") :: string),
		logField("script", script),
		logField("runtime", runtime),
		rule("-"),
		"",
		"  Runtime",
		logField("engine", diagnosticsInfo.runtime, 14),
		logField("version", diagnosticsInfo.version, 14),
		"",
		"  System",
		logField("os", diagnosticsInfo.os, 14),
		logField("arch", diagnosticsInfo.arch, 14),
		"",
		"  Capabilities",
	}

	for capability, supported in diagnosticsInfo.capabilities do
		table.insert(lines, logField(capability, tostring(supported), 26))
	end

	table.insert(lines, "")
	table.insert(lines, rule())
	table.insert(lines, "  Session Output (last 200 lines)")
	table.insert(lines, rule())

	return table.concat(lines, "\n")
end

local function flushChunk(chunk: string, logLines: { string }, partial: { string })
	local text = partial[1] .. chunk
	local position = 1

	while true do
		local newlinePosition = string.find(text, "\n", position, true)

		if not newlinePosition then
			partial[1] = string.sub(text, position)
			break
		end

		table.insert(logLines, string.sub(text, position, newlinePosition - 1))

		if #logLines > LOG_MAX then
			table.remove(logLines, 1)
		end

		position = newlinePosition + 1
	end
end

local function pipeStream(stream: any, writeFunction: (data: string) -> (), logLines: { string }, partial: { string })
	StdPolyfills.task.spawn(function()
		while true do
			local chunk: string? = stream:read(256)

			if not chunk or chunk == "" then
				break
			end

			local sanitizedChunk = redact.sanitize(chunk)

			writeFunction(sanitizedChunk)
			flushChunk(sanitizedChunk, logLines, partial)
		end
	end)
end

return command
	.new()
	:setName("capture")
	:setDescription("Run a Discord bot script and capture its output for debugging")
	:setCallback(function(context)
		local runtime: string = context.commandArguments.runtime
		local script: string = context.commandArguments.script
		local logPath = `debugify-{os.time()}.log`

		print(`\n  [debuggify] starting '{script}' via {runtime}`)
		print(`  [debuggify] logging to {logPath}`)
		print("  [debuggify] press Esc to stop\n")

		local diagnosticsInfo = diagnostics.gather()
		local logLines: { string } = {}
		local stdoutPartial = { "" }
		local stderrPartial = { "" }
		local childEnv = table.clone(StdPolyfills.process.getEnv())

		childEnv["NO_COLOR"] = "1"
		childEnv["DISCORD_LUAU_LOG_LEVEL"] = "Debug"

		StdPolyfills.io.terminal.enableRawMode()

		-- selene: allow(undefined_variable)
		local child = zune.process.create(
			runtime,
			{ "run", script },
			{ stdout = "pipe", stderr = "pipe", env = childEnv }
		)

		pipeStream(child.stdout, StdPolyfills.io.stdoutWrite, logLines, stdoutPartial)
		pipeStream(child.stderr, StdPolyfills.io.stderrWrite, logLines, stderrPartial)

		StdPolyfills.task.spawn(function()
			while true do
				local byte = StdPolyfills.io.stdinRead(1)

				if byte == "" or byte == ESC then
					child:kill()
					break
				end
			end
		end)

		child:wait()

		StdPolyfills.io.terminal.restoreMode()

		local footer = {
			"",
			rule(),
			`  Session ended : {os.date("!%Y-%m-%d %H:%M:%S UTC")}`,
			rule(),
		}

		local content = buildLogHeader(diagnosticsInfo, script, runtime)
			.. "\n"
			.. table.concat(logLines, "\n")
			.. "\n"
			.. table.concat(footer, "\n")

		StdPolyfills.fileSystem.writeFile(logPath, content)

		print(`\n  [debuggify] process exited — log saved to {logPath}`)
	end)
	:addArgument({
		name = "runtime",
		type = "string",
		required = true,
		description = "Runtime executable to use (e.g. zune, lune)",
	})
	:addArgument({
		name = "script",
		type = "string",
		required = true,
		description = "Path to the bot entry script (e.g. src/init.luau)",
	})
	:build()
