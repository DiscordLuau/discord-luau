local Task = require("@lune/task")

local DEFAULT_QUEUE_FREQUENCY = 0

local Scheduler = {}

Scheduler.Prototype = {}
Scheduler.Interface = {}

function Scheduler.Prototype:SpawnWorker()
	table.insert(
		self.Workers,
		Task.spawn(function()
			while true do
				self:Cycle()

				Task.wait(self.Frequency)
			end
		end)
	)
end

function Scheduler.Prototype:StopWorker()
	if #self.Workers == 0 then
		return
	end

	local thread = table.remove(self.Workers, 1)

	Task.cancel(thread)
end

function Scheduler.Prototype:SetFrequency(frequency)
	self.Frequency = frequency
end

function Scheduler.Prototype:Cycle()
	local item = table.remove(self.Stack, 1)

	if not item then
		return
	end

	table.insert(self.Processing, true)

	pcall(item)

	table.remove(self.Processing, 1)
end

function Scheduler.Prototype:IsActive()
	return #self.Processing > 0 or self:Size() > 0
end

function Scheduler.Prototype:SetLimit(limit)
	self.Limit = limit
end

function Scheduler.Prototype:RemoveTask(object)
	local taskIndex = table.find(self.Stack, object)

	if taskIndex then
		table.remove(self.Stack, taskIndex)
	end
end

function Scheduler.Prototype:AddTask(object)
	if self.Limit and self:Size() > self.Limit then
		return
	end

	table.insert(self.Stack, object)
end

function Scheduler.Prototype:AddTaskAsync(object)
	while self.Limit and self:Size() > self.Limit do
		Task.wait()
	end

	table.insert(self.Stack, object)
end

function Scheduler.Interface.new(threadCount)
	local self = setmetatable({
		Stack = {},
		Processing = {},
		Workers = {},
		Limit = nil,
		Frequency = DEFAULT_QUEUE_FREQUENCY,
	}, { __index = Scheduler.Prototype })

	for _ = 1, threadCount or 0 do
		self:SpawnWorker()
	end

	return self
end

return Scheduler.Interface