-- // External Imports
local Signal = require("Signal")

local Task = require("@lune/task")

-- // Constants
local DEFAULT_LOGGING_SCHEMA = "[%s][%s] :: %s"
local MAXIMUM_CACHED_LOGS = 500
local PRETTY_TABLE_TAB = "\t"

-- // Module
local Logger = { }

Logger.Type = "Logger"

Logger.LogLevel = 1
Logger.Schema = DEFAULT_LOGGING_SCHEMA

Logger.Cache = setmetatable({}, { __mode = "kv" })

Logger.Functions = { }
Logger.Interface = { }
Logger.Instances = { }
Logger.Prototype = { }

Logger.Interface.onMessageOut = Signal.new()
Logger.Interface.LogLevel = {
	["Debug"] = 1,
	["Log"] = 2,
	["Warn"] = 3,
	["Error"] = 4,
	["Critical"] = 5,
}

-- // QoL functions
function Logger.Functions:AddScopeToString(string)
	local stringSplit = string.split(string, "\n")

	for index, value in stringSplit do
		if index == 1 then
			continue
		end

		stringSplit[index] = string.format("%s%s", PRETTY_TABLE_TAB, value)
	end

	return table.concat(stringSplit, "\n")
end

function Logger.Functions:ToPrettyString(...)
	local stringifiedObjects = { }

	for _, object in { ... } do
		local objectType = typeof(object)

		if objectType == "table" then
			if Logger.Cache[object] then
				table.insert(stringifiedObjects, `RecursiveTable<{tostring(object)}>`)

				continue
			else
				Logger.Cache[object] = true
			end

			local tableSchema = "{\n"
			local tableEntries = 0

			for key, value in object do
				tableEntries += 1

				key = self:ToPrettyString(key)

				if typeof(value) == "table" then
					value = self:AddScopeToString(self:ToPrettyString(value))
				else
					value = self:ToPrettyString(value)
				end

				tableSchema ..= string.format("%s[%s] = %s,\n", PRETTY_TABLE_TAB, key, value)
			end

			table.insert(stringifiedObjects, tableEntries == 0 and "{ }" or tableSchema .. "}")
		elseif objectType == "string" then
			table.insert(stringifiedObjects, string.format('"%s"', object))
		else
			table.insert(stringifiedObjects, tostring(object))
		end
	end

	return table.concat(stringifiedObjects, " ")
end

function Logger.Functions:FormatVaradicArguments(...)
	local args = { ... }

	local message = string.rep("%s ", #args)
	local messageType = typeof(args[1])

	if messageType == "string" then
		message = table.remove(args, 1)
	end

	for index, value in args do
		args[index] = self:ToPrettyString(value)
	end

	table.clear(Logger.Cache)

	return string.format(
		message,
		table.unpack(args)
	)
end

function Logger.Functions:FormatMessageSchema(schema: string, source: string, ...)
	source = source or debug.info(2, "s")

	return string.format(
		schema, source, ...
	)
end

-- // Prototype functions
--[[
	Assertions, however written through our logger, if the condition isn't met, the logger will call :error on itself with the given message.

	### Parameters
	- **condition**: *the condition we are going to validate*
	- **...**: *anything, Logger is equipped to parse & display all types.*

	---
	Example:

	```lua
		local Logger = Logger.new("Logger")

		Logger:Assert(1 == 1, "Hello, World!") -- > will output: nothing
		Logger:Assert(1 == 2, "Hello, World!") -- > will output: [Logger][error]: "Hello, World!" <stack attached>
	```
]]
function Logger.Prototype:Assert(condition, ...): ()
	if not condition then
		self:Error(...)
	end
end

--[[
	Create a new log for 'critical', critical being deployed in a situation where something has gone terribly wrong.

	### Parameters
	- **...**: *anything, Logger is equipped to parse & display all types.*

	---
	Example:

	```lua
		local Logger = Logger.new("Logger")

		Logger:Critical("Hello, World!") -- > will output: [Logger][critical]: "Hello, World!" <stack attached>
	```
]]
function Logger.Prototype:Critical(...): ()
	local outputMessage = Logger.Functions:FormatMessageSchema(self.schema or Logger.Schema, self.id, "critical", Logger.Functions:FormatVaradicArguments(...))

	table.insert(self.logs, 1, { "critical", outputMessage, self.id })
	if #self.logs > MAXIMUM_CACHED_LOGS then
		table.remove(self.logs, MAXIMUM_CACHED_LOGS)
	end

	if self.level > Logger.Interface.LogLevel.Critical or Logger.LogLevel > Logger.Interface.LogLevel.Critical then
		Task.cancel(coroutine.running())

		return
	end

	Logger.Interface.onMessageOut:Fire(self.id or "<unknown>", outputMessage)

	error(outputMessage, 2)
end

--[[
	Create a new log for 'error', this is for errors raised through a developers code on purpose.

	### Parameters
	- **...**: *anything, Logger is equipped to parse & display all types.*

	---
	Example:

	```lua
		local Logger = Logger.new("Logger")

		Logger:Error("Hello, World!") -- > will output: [Logger][error]: "Hello, World!" <stack attached>
	```
]]
function Logger.Prototype:Error(...): ()
	local outputMessage = Logger.Functions:FormatMessageSchema(self.schema or Logger.Schema, self.id, "error", Logger.Functions:FormatVaradicArguments(...))

	table.insert(self.logs, 1, { "error", outputMessage, self.id })
	if #self.logs > MAXIMUM_CACHED_LOGS then
		table.remove(self.logs, MAXIMUM_CACHED_LOGS)
	end

	if self.level > Logger.Interface.LogLevel.Error or Logger.LogLevel > Logger.Interface.LogLevel.Error then
		Task.cancel(coroutine.running())

		return
	end

	Logger.Interface.onMessageOut:Fire(self.id or "<unknown>", outputMessage)

	error(outputMessage, 2)
end

--[[
	Create a new log for 'warn', this is for informing developers about something which takes precedence over a log

	### Parameters
	- **...**: *anything, Logger is equipped to parse & display all types.*

	---
	Example:

	```lua
		local Logger = Logger.new("Logger")

		Logger:Warn("Hello, World!") -- > will output: [Logger][warn]: "Hello, World!"
	```
]]
function Logger.Prototype:Warn(...): ()
	local outputMessage = Logger.Functions:FormatMessageSchema(self.schema or Logger.Schema, self.id, "warn", Logger.Functions:FormatVaradicArguments(...))

	table.insert(self.logs, 1, { "warn", outputMessage, self.id })
	if #self.logs > MAXIMUM_CACHED_LOGS then
		table.remove(self.logs, MAXIMUM_CACHED_LOGS)
	end

	if self.level > Logger.Interface.LogLevel.Warn or Logger.LogLevel > Logger.Interface.LogLevel.Warn then
		return
	end

	Logger.Interface.onMessageOut:Fire(self.id or "<unknown>", outputMessage)

	print(outputMessage)
end

--[[
	Create a new log for 'log', this is for general logging - ideally what we would use in-place of print.

	### Parameters
	- **...**: *anything, Logger is equipped to parse & display all types.*

	---
	Example:

	```lua
		local Logger = Logger.new("Logger")

		Logger:Log("Hello, World!") -- > will output: [Logger][log]: "Hello, World!"
	```
]]
function Logger.Prototype:Log(...): ()
	local outputMessage = Logger.Functions:FormatMessageSchema(self.schema or Logger.Schema, self.id, "log", Logger.Functions:FormatVaradicArguments(...))

	table.insert(self.logs, 1, { "log", outputMessage, self.id })
	if #self.logs > MAXIMUM_CACHED_LOGS then
		table.remove(self.logs, MAXIMUM_CACHED_LOGS)
	end

	if self.level > Logger.Interface.LogLevel.Log or Logger.LogLevel > Logger.Interface.LogLevel.Log then
		return
	end

	Logger.Interface.onMessageOut:Fire(self.id or "<unknown>", outputMessage)

	print(outputMessage)
end

--[[
	Create a new log for 'debug', typically we should only use 'debug' when debugging code or leaving hints for developers.

	### Parameters
	- **...**: *anything, Logger is equipped to parse & display all types.*

	---
	Example:

	```lua
		local Logger = Logger.new("Logger")

		Logger:Debug("Hello, World!") -- > will output: [Logger][debug]: "Hello, World!"
	```
]]
function Logger.Prototype:Debug(...): ()
	local outputMessage = Logger.Functions:FormatMessageSchema(self.schema or Logger.Schema, self.id, "debug", Logger.Functions:FormatVaradicArguments(...))

	table.insert(self.logs, 1, { "debug", outputMessage, self.id })
	if #self.logs > MAXIMUM_CACHED_LOGS then
		table.remove(self.logs, MAXIMUM_CACHED_LOGS)
	end

	if self.level > Logger.Interface.LogLevel.Debug or Logger.LogLevel > Logger.Interface.LogLevel.Debug then
		return
	end

	Logger.Interface.onMessageOut:Fire(self.id or "<unknown>", outputMessage)

	print(outputMessage)
end

--[[
	Set an log level for this logger, log levels assigned per logger override the global log level.

	### Parameters
	- **logLevel**: *The logLevel priority you only want to show in output*
		* *Log Levels are exposed through `Logger.LogLevel`*

	### Returns
	- **Array**: *The array of logs created from this logger*

	---
	Example:

	```lua
		local Logger = LoggerModule.new("Logger")

		LoggerModule.setGlobalLogLevel(Logger.LogLevel.Warn)

		Logger:Log("Hello, World!") -- this will NOT output anything
		Logger:Warn("Hello, World!") -- this will output something

		Logger:SetLogLevel(Logger.LogLevel.Log)

		Logger:Log("Hello, World!") -- this will output something
		Logger:Warn("Hello, World!") -- this will output something
	```
]]
function Logger.Prototype:SetLogLevel(logLevel: number): ()
	self.level = logLevel
end

--[[
	Sets the state of the logger, state depicts if the logger can log messages into the output.

	### Parameters
	- **state**: *A bool to indicate weather this logger is enabled or not.*

	---
	Example:

	```lua
		local Logger = Logger.new("Logger")

		Logger:Log("Hello, World!") -- > will output: [Logger][log]: "Hello, World!"
		Logger:SetState(false)
		Logger:Log("Hello, World!") -- > will output: nothing
	```
]]
function Logger.Prototype:SetState(state: boolean): ()
	self.enabled = state
end

--[[
	Fetch an array of logs generated through this logger

	### Parameters
	- **count**: *The amount of logs you're trying to retrieve*

	### Returns
	- **Array**: *The array of logs created from this logger*

	---
	Example:

	```lua
		local Logger = Logger.new("Logger")

		Logger:Log("Hello, World!") -- > [Logger][log]: "Hello, World!"
		Logger:FetchLogs() -- > [=[
			{
				"log",
				"[Logger][log]: \"Hello, World!\"",
				"Logger"
			}
		]=]--
	```
]]
function Logger.Prototype:FetchLogs(count: number): { [number]: { logType: string, message: string, logId: string } }
	local fetchedLogs = {}

	if not count then
		return self.logs
	end

	for index = 1, count do
		if not self.logs[index] then
			return fetchedLogs
		end

		table.insert(fetchedLogs, self.logs[index])
	end

	return fetchedLogs
end

--[[
	Returns a prettified string version of the logger table.

	---
	Example:

	```lua
		local Value = State.new(0)

		print(tostring(Value)) -- Value<0>
	```
]]
function Logger.Prototype:ToString(): string
	return `{Logger.Type}<"{tostring(self.id)}">`
end

-- // Module functions
--[[
	Set the global log level for all loggers, a log level is the priority of a log, priorities are represented by a number.

	### Parameters
	- **logLevel**: *The logLevel priority you only want to show in output*
		* *Log Levels are exposed through `Logger.LogLevel`*

	---
	Example:

	```lua
		Logger.setGlobalLogLevel(Logger.LogLevel.Warn)

		Logger:log("Hello, World!") -- this will NOT output anything
		Logger:warn("Hello, World!") -- this will output something
	```
]]
function Logger.Interface.setGlobalLogLevel(logLevel: number): ()
	Logger.LogLevel = logLevel
end

--[[
	Set the global schema for all loggers, a schema is how we display the output of a log.

	### Parameters
	- **schema**: *The schema you want all loggers to follow*
		* **schema format**: *loggerName / logType / logMessage*
		* **example schema**: *[%s][%s]: %s*

	---
	Example:

	```lua
		Logger.setGlobalSchema("[%s][%s]: %s")

		Logger:log("Hello, World!") -- > [<ReporterName>][log]: Hello, World!
	```
]]
function Logger.Interface.setGlobalSchema(schema: string): ()
	Logger.Schema = schema
end

--[[
	Fetch a `Logger` object through it's given `logId`

	### Parameters
	- **logId?**: *The name of the `Logger` object you want to fetch*

	### Returns
	- **Logger**: *The constructed `Logger` prototype*
	- **nil**: *Unable to find the `Logger`*

	---
	Example:

	```lua
		Logger.get("Logger"):log("Hello, World!") -- > [Logger][log]: "Hello, World!"
	```
]]
function Logger.Interface.get(logId: string)
	return Logger.Instances[logId]
end

--[[
	Constructor to generate a `Logger` prototype

	### Parameters
	- **logId?**: *The name of the `Logger`, this will default to the calling script name.*
	- **schema?**: *The schema this paticular `Logger` will follow*

	### Returns
	- **Logger**: The constructed `Logger` prototype

	---
	Example:

	```lua
		Logger.new("Example"):log("Hello, World!") -- > [Example][log]: "Hello, World!"
	```
]]
function Logger.Interface.new(logId: string?, schema: string?)
	local self = setmetatable({
		id = logId,
		level = Logger.Interface.LogLevel.Debug,
		schema = schema,
		enabled = true,
		logs = { },
	}, {
		__index = Logger.Prototype,
		__type = Logger.Type,
		__tostring = function(obj)
			return obj:ToString()
		end
	})

	if logId then
		Logger.Instances[self.id] = self
	end

	return self
end

--[[
	Validate if an object is a 'Logger' object

	### Parameters
	- **object**: *potentially an 'Logger' object*

	---
	Example:

	```lua
		local object = Logger.new("Test")

		if Logger.is(object) then
			...
		end
	```
]]
function Logger.Interface.is(object): boolean
	if not object or type(object) ~= "table" then
		return false
	end

	local metatable = getmetatable(object)

	return metatable and metatable.__type == Logger.Type
end

return Logger.Interface