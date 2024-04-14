local Task = require("@lune/task")

local Construct = require("../../Utils/Construct")

local Console = require("../../Vendor/Console")

local DEFAULT_QUEUE_FREQUENCY = 0

local HTTPScheduler = {}

HTTPScheduler.Prototype = {}
HTTPScheduler.Interface = {}

HTTPScheduler.Prototype.type = "HTTPScheduler"

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

function HTTPScheduler.Prototype.stopWorker(self: HTTPScheduler)
	if #self.workers == 0 then
		return
	end

	local thread = table.remove(self.workers, 1)

	Task.cancel(thread)
end

function HTTPScheduler.Prototype.setFrequency(self: HTTPScheduler, frequency: number)
	self.frequency = frequency
end

function HTTPScheduler.Prototype.cycle(self: HTTPScheduler)
	local item = table.remove(self.stack, 1)

	if not item then
		return
	end

	table.insert(self.processing, true)

	local success, response = pcall(item)

	if not success then
		self.reporter:warn(`HTTP Shceduled call failed: '{response}'`)
	end

	table.remove(self.processing, 1)
end

function HTTPScheduler.Prototype.isActive(self: HTTPScheduler)
	return #self.processing > 0
end

function HTTPScheduler.Prototype.setLimit(self: HTTPScheduler, limit: number)
	self.limit = limit
end

function HTTPScheduler.Prototype.removeTask(self: HTTPScheduler, object: (...any) -> ())
	local taskIndex = table.find(self.stack, object)

	if taskIndex then
		table.remove(self.stack, taskIndex)
	end
end

function HTTPScheduler.Prototype.addTask(self: HTTPScheduler, object: (...any) -> ())
	local thread = coroutine.running()

	table.insert(self.stack, function()
		local response = object()

		coroutine.resume(thread, response)
	end)

	return coroutine.yield()
end

function HTTPScheduler.Interface.new(threadCount: number?)
	local self = Construct({
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

export type HTTPScheduler = typeof(HTTPScheduler.Interface.new(0))

return HTTPScheduler.Interface