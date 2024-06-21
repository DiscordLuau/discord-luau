local Task = require("@std/task")

local Console = require("@dep/console")

local construct = require("@util/construct")

local DEFAULT_QUEUE_FREQUENCY = 0

--[=[
	@class Network.HTTPScheduler

	The `HTTPScheduler` class manages the scheduling of HTTP tasks. It allows for the addition, removal, and execution of tasks at a specified frequency.

	:::caution
	This class is internal and should not be used directly by developers. Instead, use the provided public interfaces and methods to manage HTTP scheduling.
	:::
]=]
local HTTPScheduler = {}

HTTPScheduler.Prototype = {}
HTTPScheduler.Interface = {}

HTTPScheduler.Prototype.type = "HTTPScheduler"

--[=[
	@within Network.HTTPScheduler
	@method spawnWorker
	@private
	Spawns a new worker task that cycles through scheduled tasks at the specified frequency.

	@param self HTTPScheduler
]=]
function HTTPScheduler.Prototype.spawnWorker(self: HTTPScheduler)
	table.insert(
		self.workers,
		Task.spawn(function()
			while true do
				self:cycle()

				Task.wait(self.frequency)
			end
		end)
	)
end

--[=[
	@within Network.HTTPScheduler
	@method stopWorker
	@private
	Stops and removes a worker task.

	@param self HTTPScheduler
]=]
function HTTPScheduler.Prototype.stopWorker(self: HTTPScheduler)
	local thread = table.remove(self.workers, 1)

	if not thread then
		return
	end

	Task.cancel(thread)
end

--[=[
	@within Network.HTTPScheduler
	@method setFrequency
	@private
	Sets the frequency at which tasks are cycled.

	@param self HTTPScheduler
	@param frequency number -- The frequency in seconds.
]=]
function HTTPScheduler.Prototype.setFrequency(self: HTTPScheduler, frequency: number)
	self.frequency = frequency
end

--[=[
	@within Network.HTTPScheduler
	@method cycle
	@private
	Processes the next task in the stack.

	@param self HTTPScheduler
]=]
function HTTPScheduler.Prototype.cycle(self: HTTPScheduler)
	local item = table.remove(self.stack, 1)

	if not item then
		return
	end

	table.insert(self.processing, true)

	local values = { pcall(item) }

	if not values[1] then
		self.reporter:warn(`HTTP Scheduled call failed: '{values[2]}'`)
	end

	table.remove(self.processing, 1)
end

--[=[
	@within Network.HTTPScheduler
	@method isActive
	@private
	Checks if there are any tasks currently being processed.

	@param self HTTPScheduler
	@return boolean -- Returns `true` if there are tasks being processed, `false` otherwise.
]=]
function HTTPScheduler.Prototype.isActive(self: HTTPScheduler)
	return #self.processing > 0
end

--[=[
	@within Network.HTTPScheduler
	@method setLimit
	@private
	Sets the limit for the number of tasks that can be scheduled.

	@param self HTTPScheduler
	@param limit number -- The maximum number of tasks.
]=]
function HTTPScheduler.Prototype.setLimit(self: HTTPScheduler, limit: number)
	self.limit = limit
end

--[=[
	@within Network.HTTPScheduler
	@method removeTask
	@private
	Removes a task from the scheduler.

	@param self HTTPScheduler
	@param object function -- The task function to remove.
]=]
function HTTPScheduler.Prototype.removeTask<T>(self: HTTPScheduler, object: (...T) -> ...T)
	local taskIndex = table.find(self.stack, object)

	if taskIndex then
		table.remove(self.stack, taskIndex)
	end
end

--[=[
	Adds a task to the scheduler.
	
	@private
	@method addTask
	@param self HTTPScheduler
	@param object function -- The task function to add.
	@within Network.HTTPScheduler
	@return any -- Returns the result of the task function.
]=]
function HTTPScheduler.Prototype.addTask<T>(self: HTTPScheduler, object: (...T) -> ...T)
	local thread = coroutine.running()

	table.insert(self.stack, function()
		coroutine.resume(thread, object())
	end)

	return coroutine.yield()
end

--[=[
	Creates a new instance of `HTTPScheduler`.
	
	@private
	@function new
	@param threadCount number? -- The number of worker threads to spawn.
	@within Network.HTTPScheduler
	@return HTTPScheduler
]=]
function HTTPScheduler.Interface.new(threadCount: number?): HTTPScheduler
	--[=[
		@prop stack { () -> () }
		@within Network.HTTPScheduler
	]=]

	--[=[
		@prop processing { boolean }
		@within Network.HTTPScheduler
	]=]

	--[=[
		@prop workers { thread }
		@within Network.HTTPScheduler
	]=]

	--[=[
		@prop reporter Vendor.Console
		@within Network.HTTPScheduler
	]=]

	--[=[
		@prop limit number?
		@within Network.HTTPScheduler
	]=]

	--[=[
		@prop frequency number
		@within Network.HTTPScheduler
	]=]

	local self = construct({
		stack = {},
		processing = {},
		workers = {},

		reporter = Console.new("⚠️ HTTP Scheduler"),

		limit = nil,
		frequency = DEFAULT_QUEUE_FREQUENCY,
	}, HTTPScheduler.Prototype)

	for _ = 1, threadCount or 0 do
		self:spawnWorker()
	end

	return self
end

export type HTTPScheduler = typeof(HTTPScheduler.Prototype) & {
	stack: { () -> () },
	processing: { boolean },
	workers: { thread },

	reporter: Console.Console,

	limit: number?,
	frequency: number,
}

return HTTPScheduler.Interface
