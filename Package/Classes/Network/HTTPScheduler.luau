local Task = require("@lune/task")

local Construct = require("../../Utils/Construct")

local Console = require("../../Vendor/Console")

local DEFAULT_QUEUE_FREQUENCY = 0

local HTTPScheduler = {}

HTTPScheduler.Prototype = {}
HTTPScheduler.Interface = {}

function HTTPScheduler.Prototype.spawnWorker(self: HTTPScheduler)
	table.insert(
		self.Workers,
		Task.spawn(function()
			while true do
				self:cycle()

				Task.wait(self.Frequency)
			end
		end)
	)
end

function HTTPScheduler.Prototype.stopWorker(self: HTTPScheduler)
	if #self.Workers == 0 then
		return
	end

	local thread = table.remove(self.Workers, 1)

	Task.cancel(thread)
end

function HTTPScheduler.Prototype.setFrequency(self: HTTPScheduler, frequency: number)
	self.Frequency = frequency
end

function HTTPScheduler.Prototype.cycle(self: HTTPScheduler)
	local item = table.remove(self.Stack, 1)

	if not item then
		return
	end

	table.insert(self.Processing, true)

	local success, response = pcall(item)

	if not success then
		self.Reporter:warn(`HTTP Shceduled call failed: '{response}'`)
	end

	table.remove(self.Processing, 1)
end

function HTTPScheduler.Prototype.isActive(self: HTTPScheduler)
	return #self.Processing > 0
end

function HTTPScheduler.Prototype.setLimit(self: HTTPScheduler, limit: number)
	self.Limit = limit
end

function HTTPScheduler.Prototype.removeTask(self: HTTPScheduler, object: (...any) -> ())
	local taskIndex = table.find(self.Stack, object)

	if taskIndex then
		table.remove(self.Stack, taskIndex)
	end
end

function HTTPScheduler.Prototype.addTask(self: HTTPScheduler, object: (...any) -> ())
	local thread = coroutine.running()

	table.insert(self.Stack, function()
		local response = object()

		coroutine.resume(thread, response)
	end)

	return coroutine.yield()
end

function HTTPScheduler.Interface.new(threadCount: number?)
	local self = Construct({
		Stack = {},
		Processing = {},
		Workers = {},

		Reporter = Console.new("⚠️ HTTP Scheduler"),

		Limit = nil,
		Frequency = DEFAULT_QUEUE_FREQUENCY,
	}, HTTPScheduler.Prototype)

	for _ = 1, threadCount or 0 do
		self:spawnWorker()
	end

	return self
end

export type HTTPScheduler = typeof(HTTPScheduler.Interface.new(0))

return HTTPScheduler.Interface