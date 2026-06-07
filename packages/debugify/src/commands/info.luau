local CliBuilder = require("../../luau_packages/cli_builder")
local StdPolyfills = require("../../luau_packages/std_polyfills")
local diagnostics = require("../utilities/diagnostics")

local command = CliBuilder.command

local color = not StdPolyfills.process.getEnv()["NO_COLOR"]

local BOLD = if color then "\x1b[1m" else ""
local DIM = if color then "\x1b[2m" else ""
local CYAN = if color then "\x1b[36m" else ""
local GREEN = if color then "\x1b[32m" else ""
local GREY = if color then "\x1b[90m" else ""
local RESET = if color then "\x1b[0m" else ""

local function field(key: string, value: string, keyWidth: number)
	local padding = string.rep(" ", keyWidth - #key)
	local colored = if value == "true"
		then GREEN .. value .. RESET
		elseif value == "false" then GREY .. value .. RESET
		else BOLD .. value .. RESET
	print(`  {key}{padding}{colored}`)
end

local function section(title: string)
	print()
	print(`  {CYAN}{BOLD}{title}{RESET}`)
	print(`  {DIM}{string.rep("─", 36)}{RESET}`)
end

return command
	.new()
	:setName("info")
	:setDescription("Display environment and runtime diagnostic information")
	:setCallback(function(_context)
		local diagnosticsInfo = diagnostics.gather()

		print()
		print(`{BOLD}  discord-luau debuggify{RESET}`)
		print(`  {DIM}{string.rep("─", 40)}{RESET}`)

		section("Runtime")
		field("engine", diagnosticsInfo.runtime, 14)
		field("version", diagnosticsInfo.version, 14)

		section("System")
		field("os", diagnosticsInfo.os, 14)
		field("arch", diagnosticsInfo.arch, 14)

		section("Capabilities")
		for capability, supported in diagnosticsInfo.capabilities do
			field(capability, tostring(supported), 26)
		end

		print()
	end)
	:build()
