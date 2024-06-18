local Task = require("@Std/Task")

local Construct = require("@Utils/Construct")

--[=[
	@class Network.HTTPRatelimit

	The `HTTPRatelimit` class manages the rate limiting for HTTP requests. It tracks the remaining requests that can be made and handles the reset of these limits after a specified duration.

	:::caution
	This class is internal and should not be used directly by developers. Instead, use the provided public interfaces and methods to manage rate limits.
	:::
]=]
local HTTPRatelimit = {}

HTTPRatelimit.Prototype = {}
HTTPRatelimit.Interface = {}

HTTPRatelimit.Prototype.type = "HTTPRatelimit"

--[=[
	Sets the remaining number of requests that can be made.
	
	@private
	@method setRemaining
	@param self HTTPRatelimit
	@param remaining number -- The number of remaining requests.
	@within Network.HTTPRatelimit
]=]
function HTTPRatelimit.Prototype.setRemaining(self: HTTPRatelimit, remaining: number)
	self.remaining = remaining
end

--[=[
	Resets the remaining requests after a specified number of seconds.
	
	@private
	@method resetAfter
	@param self HTTPRatelimit
	@param seconds number -- The number of seconds after which to reset the remaining requests.
	@within Network.HTTPRatelimit
]=]
function HTTPRatelimit.Prototype.resetAfter(self: HTTPRatelimit, seconds: number)
	Task.delay(seconds, function()
		self.remaining = math.min(self.remaining + 1, self.limit)
	end)
end

--[=[
	Sets the maximum number of requests that can be made.
	
	@private
	@method setLimit
	@param self HTTPRatelimit
	@param limit number -- The maximum number of requests.
	@within Network.HTTPRatelimit
]=]
function HTTPRatelimit.Prototype.setLimit(self: HTTPRatelimit, limit: number)
	self.limit = limit
end

--[=[
	Checks if the rate limit has been consumed.
	
	@private
	@method isConsumed
	@param self HTTPRatelimit
	@within Network.HTTPRatelimit
	@return boolean -- Returns `true` if the rate limit is consumed, `false` otherwise.
]=]
function HTTPRatelimit.Prototype.isConsumed(self: HTTPRatelimit)
	return self.remaining <= 0
end

--[=[
	Creates a new instance of `HTTPRatelimit`.
	
	@private
	@function new
	@param remaining number? -- The initial number of remaining requests.
	@param limit number? -- The initial limit of requests.
	@within Network.HTTPRatelimit
	@return HTTPRatelimit
]=]
function HTTPRatelimit.Interface.new(remaining: number?, limit: number?)
	--[=[
		@prop remaining number
		@within Network.HTTPRatelimit
	]=]

	--[=[
		@prop limit number
		@within Network.HTTPRatelimit
	]=]

	--[=[
		@prop resetAfterThread thread?
		@within Network.HTTPRatelimit
	]=]

	return Construct({
		remaining = remaining or 0,
		limit = limit or 0,
	}, HTTPRatelimit.Prototype)
end

export type HTTPRatelimit = typeof(HTTPRatelimit.Prototype) & {
	remaining: number,
	limit: number,

	resetAfterThread: thread?,
}

return HTTPRatelimit.Interface
