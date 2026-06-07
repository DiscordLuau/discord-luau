--[=[
	@class Logger
	@__index Prototype

	Logger, a simple logging implementation for Discord Luau.

	This implementation is based on the following document:
		- https://www.sumologic.com/glossary/log-levels/

	Please defer to the above document for when it is appropriate to use each log level.
]=]

local stdPolyfills = require("@self/../luau_packages/std_polyfills")

local isRoblox = stdPolyfills.runtime.getRuntime() == "Roblox"

local environment = stdPolyfills.process.getEnv()
local useAnsi = not isRoblox and environment["NO_COLOR"] == nil

local DIM = if useAnsi then "\27\91\50\109" else ""
local BOLD = if useAnsi then "\27\91\49\109" else ""
local RESET = if useAnsi then "\27\91\48\109" else ""
local CYAN = if useAnsi then "\27\91\51\54\109" else ""
local BLUE = if useAnsi then "\27\91\51\52\109" else ""
local YELLOW = if useAnsi then "\27\91\51\51\109" else ""
local RED = if useAnsi then "\27\91\51\49\109" else ""

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

local envLevelName = environment["DISCORD_LUAU_LOG_LEVEL"]
local envLevelFloor = envLevelName and table.find(LOGGER_LOG_LEVELS, envLevelName) or nil

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

	Function responsible for setting the log level of the logger. Log levels with an index below the
		configured level will be suppressed. For example, setting the level to "Warn" suppresses Debug,
		Info, and Notice, while Warn and above are still emitted.
]=]
function Logger.Prototype.setLogLevel(self: Logger, logLevel: LogLevel)
	local logLevelIndex = table.find(LOGGER_LOG_LEVELS, logLevel)

	assert(logLevelIndex, `Invalid log level: {logLevel}`)

	self.logLevel = if envLevelFloor then math.min(logLevelIndex, envLevelFloor) else logLevelIndex
end

function Logger.Prototype.getLogLevel(self: Logger): LogLevel
	return LOGGER_LOG_LEVELS[self.logLevel] :: LogLevel
end

--[=[
	@within Logger

	Replaces the default `print` output with a custom sink. The sink receives the fully-formatted
	log line (including ANSI codes) as a single string. Useful for capturing output in tests.
]=]
function Logger.Prototype.setSink(self: Logger, sink: (message: string) -> ())
	self.sink = sink
end

function Logger.Interface.new(name: string, logLevel: LogLevel?): Logger
	local logLevelIndex = logLevel and table.find(LOGGER_LOG_LEVELS, logLevel)

	assert(not logLevel or logLevelIndex, `Invalid log level: {logLevel}`)

	local self: Logger = setmetatable({
		logLevel = if envLevelFloor then math.min(logLevelIndex or 1, envLevelFloor) else (logLevelIndex or 1),
		sink = print,
	}, { __index = Logger.Prototype }) :: any

	-- dynamically generates a method for each log level on the instance
	for logValue, logType in LOGGER_LOG_LEVELS do
		local camelCaseMethod = `{string.lower(string.sub(logType, 1, 1))}{string.sub(logType, 2, #logType)}`

		(self :: {})[camelCaseMethod] = function(_, ...)
			if logValue < self.logLevel then
				return
			end

			local logMessage = parseVaradic({ ... })
			local unixTimestampMillis = stdPolyfills.datetime.now().unixTimestampMillis
			local date = os.date("!*t", unixTimestampMillis / 1000)
			local milliseconds = unixTimestampMillis % 1000
			local time = string.format(
				"%04d-%02d-%02d %02d:%02d:%02d.%03d",
				date.year,
				date.month,
				date.day,
				date.hour,
				date.min,
				date.sec,
				milliseconds
			)

			self.sink(`{string.format(LOGGER_LOG_FORMATS[logType], time, name, logMessage)}{RESET}`)

			if logValue >= 5 and self.sink == print then
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
	sink: (message: string) -> (),

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
