local CliBuilder = require("@self/../luau_packages/cli_builder")
local StdPolyfills = require("@self/../luau_packages/std_polyfills")

local infoCommand = require("@self/commands/info")
local captureCommand = require("@self/commands/capture")

local scriptSource: string = debug.info(1, "s")
local sourceDirectory: string = string.match(scriptSource, "^(.*)[/\\][^/\\]+$") or "."
local packageDirectory: string = string.match(sourceDirectory, "^(.*)[/\\][^/\\]+$") or "."
local pesdeToml = StdPolyfills.serde.decode("toml", StdPolyfills.fileSystem.readFile(packageDirectory .. "/pesde.toml"))
local version: string = pesdeToml.version or "0.0.0"

local cli = CliBuilder.cli

cli.new()
	:setVersion(version)
	:setName("discord_luau/debuggify")
	:setDescription("Diagnostic tool for discord-luau projects.")
	:setLicense("MIT")
	:addAuthor("Async Matrix <hi@asyncmatrix.dev>")
	:setGitRepository("https://github.com/DiscordLuau/discord-luau/")
	:setBugReportUrl("https://github.com/DiscordLuau/discord-luau/issues")
	:setHomepage("https://discordluau.devcomp.xyz/")
	:setEpilog(
		"Examples:\n"
			.. "  pesde x discord_luau/debuggify info\n"
			.. "  pesde x discord_luau/debuggify capture zune src"
	)
	:addCommand(infoCommand)
	:addCommand(captureCommand)
	:run(StdPolyfills.process.getArgs())

return nil
