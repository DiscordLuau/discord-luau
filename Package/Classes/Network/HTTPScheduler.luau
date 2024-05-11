local Task = require("../../Std/Task")

local Construct = require("../../Utils/Construct")

local Console = require("../../Vendor/Console")

local DEFAULT_QUEUE_FREQUENCY = 0

--[=[
	@class Network.HTTPScheduler

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
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
	local thread = table.remove(self.workers, 1)

	if not thread then
		return
	end

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

	local values = { pcall(item) }

	if not values[1] then
		self.reporter:warn(`HTTP Shceduled call failed: '{values[2]}'`)
	end

	table.remove(self.processing, 1)
end

function HTTPScheduler.Prototype.isActive(self: HTTPScheduler)
	return #self.processing > 0
end

function HTTPScheduler.Prototype.setLimit(self: HTTPScheduler, limit: number)
	self.limit = limit
end

function HTTPScheduler.Prototype.removeTask<T>(self: HTTPScheduler, object: (...T) -> ...T)
	local taskIndex = table.find(self.stack, object)

	if taskIndex then
		table.remove(self.stack, taskIndex)
	end
end

function HTTPScheduler.Prototype.addTask<T>(self: HTTPScheduler, object: (...T) -> ...T)
	local thread = coroutine.running()

	table.insert(self.stack, function()
		coroutine.resume(thread, object())
	end)

	return coroutine.yield()
end

function HTTPScheduler.Interface.new(threadCount: number?): HTTPScheduler
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

export type HTTPScheduler = typeof(HTTPScheduler.Prototype) & {
	stack: { () -> () },
	processing: { boolean },
	workers: { thread },

	reporter: Console.Console,

	limit: number?,
	frequency: number,
}

return HTTPScheduler.Interface