local CliBuilder = require("./luau_packages/cli_builder")
local StdPolyfills = require("./lune_packages/std_polyfills")

local createCommand = require("@self/commands/create")

local Logger = require("@self/objects/logger")

local cli = CliBuilder.cli
local option = CliBuilder.option

local app = cli.new()
	:setVersion("0.1.0")
	:setName("DiscordLuau/create_app")
	:setDescription("an interactive command-line tool to scaffold a new Discord bot project in Luau.")
	:setLicense("MIT")
	:addAuthor("Async Matrix <hi@asyncmatrix.dev>")
	:setGitRepository("https://github.com/DiscordLuau/discord-luau/")
	:setBugReportUrl("https://github.com/DiscordLuau/discord-luau/issues")
	:setHomepage("https://discordluau.devcomp.xyz/")
	:setEpilog("Example: pesde x DiscordLuau/create_app --ide=vscode ~/Projects/DiscordBot")
	:addOption({
		name = "verbose",
		type = "boolean",
		description = "Verbose logs are created",
		aliases = { "V" },
	})
	:setBeforeRunHook(function(context)
		if context.globalOptions.verbose then
			Logger:setLogLevel("Debug")
		else
			Logger:setLogLevel("Warn")
		end
	end)
	:addCommand(createCommand)

app:run(StdPolyfills.process.getArgs())
