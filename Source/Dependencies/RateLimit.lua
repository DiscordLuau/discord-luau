local Task = require("@lune/task")

local RateLimit = {}

RateLimit.Type = "RateLimit"

RateLimit.Internal = {}
RateLimit.Prototype = {
	Internal = RateLimit.Internal,
}
RateLimit.Interface = {
	Internal = RateLimit.Internal,
}

function RateLimit.Prototype:SetRemaining(remaining)
	self.Remaining = remaining
end

function RateLimit.Prototype:ResetAfter(seconds)
	if self.ResetAfterThread then
		Task.cancel(self.ResetAfterThread)
	end

	self.ResetAfterThread = Task.delay(seconds, function()
		self.Remaining = self.Limit
	end)
end

function RateLimit.Prototype:SetLimit(limit)
	self.Limit = limit
end

function RateLimit.Prototype:IsConsumed()
	return self.Remaining <= 0
end

function RateLimit.Interface.new()
	return setmetatable({ }, {
		__index = RateLimit.Prototype,
		__type = RateLimit.Type,
		__tostring = function(self)
			return self:ToString()
		end,
	})
end

return RateLimit.Interface
