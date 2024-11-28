--[[
	Logger, a simple logging implementation for Discord Luau.

	This implementation is based on the following document:
		- https://www.sumologic.com/glossary/log-levels/

	Please defer to the above document for when it is appropriate to use each log level.
]]

local stdPolyfills = require("../lune_packages/std_polyfills")

local LOGGER_LOG_LEVELS = table.freeze({
	"Debug",
	"Info",
	"Notice",
	"Warn",
	"Error",
	"Critical",
	"Alert",
	"Emergency",
})

local LOGGER_LOG_FORMATS = table.freeze({
	["Debug"] = `{stdPolyfills.stdio.style("dim")}{stdPolyfills.stdio.color("reset")}[%s][DEBUG]: %s`,
	["Info"] = `{stdPolyfills.stdio.color("cyan")}[%s][INFO]: %s`,
	["Notice"] = `{stdPolyfills.stdio.color("blue")}[%s][NOTICE]: %s`,
	["Warn"] = `{stdPolyfills.stdio.color("yellow")}[%s][WARN]: %s`,
	["Error"] = `{stdPolyfills.stdio.color("red")}[%s][ERROR]: %s`,
	["Critical"] = `{stdPolyfills.stdio.color("red")}[%s][CRITICAL]: %s`,
	["Alert"] = `{stdPolyfills.stdio.style("bold")}{stdPolyfills.stdio.color("red")}[%s][DEBUG]: %s`,
	["Emergency"] = `{stdPolyfills.stdio.style("bold")}{stdPolyfills.stdio.color("red")}[%s][DEBUG]: %s`,
})

local Logger = {}

Logger.Prototype = {}
Logger.Interface = {}

--[[
	Function responsible for parsing a varadic list of arguments into a string.
]]
local function parseVaradic(args: { any }): string
	local source = ""

	for index, object in args do
		source ..= `{index ~= 1 and ", " or ""}{stdPolyfills.stdio.format(object)}`
	end

	return source
end

--[[
	Function responsible for for setting the log level of the logger, for example - if the log level
		is set to "Debug", then all log levels below, and "Debug" will be ignored.
]]
function Logger.Prototype.setLogLevel(self: Logger, logLevel: LogLevel)
	local logLevelIndex = table.find(LOGGER_LOG_LEVELS, logLevel)

	assert(logLevelIndex, `Invalid log level: {logLevel}`)

	self.logLevel = logLevelIndex
end

--[[
	Constructor for the Logger object.
]]
function Logger.Interface.new(name: string, logLevel: LogLevel?): Logger
	local logLevelIndex = logLevel and table.find(LOGGER_LOG_LEVELS, logLevel)

	local self = setmetatable(
		{
			logLevel = logLevelIndex or 1,
		} :: Logger,
		{ __index = Logger.Prototype }
	)

	-- this block of code will generate a function for each log level, and set it to the Logger object.
	for logValue, logType in LOGGER_LOG_LEVELS do
		local camelCaseMethod = `{string.lower(string.sub(logType, 1, 1))}{string.sub(logType, 2, #logType)}`;

		(self :: {})[camelCaseMethod] = function(_, ...)
			if logValue < self.logLevel then
				return
			end

			local logMessage = parseVaradic({ ... })

			print(
				`{string.format(LOGGER_LOG_FORMATS[logType], name, logMessage)}{stdPolyfills.stdio.style("reset")}{stdPolyfills.stdio.color(
					"reset"
				)}`
			)

			if logValue >= 5 then
				local thread = coroutine.running()

				stdPolyfills.task.defer(function()
					stdPolyfills.task.cancel(thread)
				end)

				coroutine.yield()
			end
		end
	end

	return self
end

export type LogLevel = "Debug" | "Info" | "Notice" | "Warn" | "Error" | "Critical" | "Alert" | "Emergency"
export type Logger = typeof(Logger.Prototype) & {
	logLevel: number,

	debug: (self: Logger, ...any) -> (),
	info: (self: Logger, ...any) -> (),
	notice: (self: Logger, ...any) -> (),
	warn: (self: Logger, ...any) -> (),
	error: (self: Logger, ...any) -> (),
	critical: (self: Logger, ...any) -> (),
	alert: (self: Logger, ...any) -> (),
	emergency: (self: Logger, ...any) -> (),
}

return Logger.Interface
