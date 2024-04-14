local Task = require("@lune/task")

local Construct = require("../../Utils/Construct")

local HTTPRatelimit = {}

HTTPRatelimit.Type = "HTTPRatelimit"

HTTPRatelimit.Prototype = {}
HTTPRatelimit.Interface = {}

function HTTPRatelimit.Prototype.setRemaining(self: HTTPRatelimit, remaining: number)
	self.Remaining = remaining
end

function HTTPRatelimit.Prototype.resetAfter(self: HTTPRatelimit, seconds: number)
	if self.ResetAfterThread then
		Task.cancel(self.ResetAfterThread)
	end

	self.ResetAfterThread = Task.delay(seconds, function()
		self.Remaining = self.Limit
	end)
end

function HTTPRatelimit.Prototype.setLimit(self: HTTPRatelimit, limit: number)
	self.Limit = limit
end

function HTTPRatelimit.Prototype.isConsumed(self: HTTPRatelimit)
	return self.Remaining <= 0
end

function HTTPRatelimit.Interface.new(remaining: number?, limit: number?)
	return Construct({
		Remaining = remaining or 0,
		Limit = limit or 0
	}, HTTPRatelimit.Prototype)
end

export type HTTPRatelimit = typeof(HTTPRatelimit.Interface.new())

return HTTPRatelimit.Interface