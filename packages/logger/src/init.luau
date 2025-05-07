--[=[
	@class Logger
	@__index Prototype

	Logger, a simple logging implementation for Discord Luau.

	This implementation is based on the following document:
		- https://www.sumologic.com/glossary/log-levels/

	Please defer to the above document for when it is appropriate to use each log level.
]=]

local stdPolyfills = require("../lune_packages/std_polyfills")

local DIM = "\27\91\50\109"
local BOLD = "\27\91\49\109"

local RESET = "\27\91\48\109"

local CYAN = "\27\91\51\54\109"
local BLUE = "\27\91\51\52\109"
local YELLOW = "\27\91\51\51\109"
local RED = "\27\91\51\49\109"

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
	["Debug"] = `{DIM}[%s][%s][DEBUG]: %s`,
	["Info"] = `{CYAN}[%s][%s][INFO]: %s`,
	["Notice"] = `{BLUE}[%s][%s][NOTICE]: %s`,
	["Warn"] = `{YELLOW}[%s][%s][WARN]: %s`,
	["Error"] = `{RED}[%s][%s][ERROR]: %s`,
	["Critical"] = `{RED}[%s][%s][CRITICAL]: %s`,
	["Alert"] = `{BOLD}{RED}[%s][%s][ALERT]: %s`,
	["Emergency"] = `{BOLD}{RED}[%s][%s][EMERGENCY]: %s`,
})

local Logger = {}

Logger.Prototype = {}
Logger.Interface = {}

--[=[
	@within Logger

	Function responsible for parsing a varadic list of arguments into a string.
]=]
local function parseVaradic(args: { any }): string
	local source = ""

	-- TODO: write a prettifier.
	for index, object in args do
		source ..= `{index ~= 1 and ", " or ""}{tostring(object)}`
	end

	return source
end

--[=[
	@within Logger

	Function responsible for for setting the log level of the logger, for example - if the log level
		is set to "Debug", then all log levels below, and "Debug" will be ignored.
]=]
function Logger.Prototype.setLogLevel(self: Logger, logLevel: LogLevel)
	local logLevelIndex = table.find(LOGGER_LOG_LEVELS, logLevel)

	assert(logLevelIndex, `Invalid log level: {logLevel}`)

	self.logLevel = logLevelIndex
end

--[=[
	@within Logger

	Function responsible for for getting the log level of the logger
]=]
function Logger.Prototype.getLogLevel(self: Logger): LogLevel
	return LOGGER_LOG_LEVELS[self.logLevel] :: LogLevel
end

--[=[
	@within Logger

	Constructor for the Logger object.
]=]
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
			local unixTimestampMillis = stdPolyfills.datetime.now().unixTimestampMillis
			local date = os.date("!*t", unixTimestampMillis / 1000)
			local milliseconds = unixTimestampMillis % 1000
			local time = string.format(
				"%04d-%02d-%02d %02d:%02d:%02d.%02d",
				date.year,
				date.month,
				date.day,
				date.hour,
				date.min,
				date.sec,
				milliseconds
			)

			print(`{string.format(LOGGER_LOG_FORMATS[logType], time, name, logMessage)}{RESET}`)

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
