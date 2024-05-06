local Task = require("../../Std/Task")

local Construct = require("../../Utils/Construct")

--[=[
	@class Network.HTTPRatelimit

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local HTTPRatelimit = {}

HTTPRatelimit.Prototype = {}
HTTPRatelimit.Interface = {}

HTTPRatelimit.Prototype.type = "HTTPRatelimit"

function HTTPRatelimit.Prototype.setRemaining(self: HTTPRatelimit, remaining: number)
	self.remaining = remaining
end

function HTTPRatelimit.Prototype.resetAfter(self: HTTPRatelimit, seconds: number)
	if self.ResetAfterThread then
		Task.cancel(self.ResetAfterThread)
	end

	self.ResetAfterThread = Task.delay(seconds, function()
		self.remaining = self.limit
	end)
end

function HTTPRatelimit.Prototype.setLimit(self: HTTPRatelimit, limit: number)
	self.limit = limit
end

function HTTPRatelimit.Prototype.isConsumed(self: HTTPRatelimit)
	return self.remaining <= 0
end

function HTTPRatelimit.Interface.new(remaining: number?, limit: number?)
	return Construct({
		remaining = remaining or 0,
		limit = limit or 0
	}, HTTPRatelimit.Prototype)
end

export type HTTPRatelimit = typeof(HTTPRatelimit.Interface.new())

return HTTPRatelimit.Interface