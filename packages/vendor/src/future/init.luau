--[[
	A luau future implementation, Futures are a simpler way to query asynchronous functions, an alternative to Future would
		be to use a promise.

	This library has Unit Tests written for it under the /tests directory.
]]

local task = require("@std-polyfills/task")
local stdio = require("@std-polyfills/stdio")

local Future = {}

Future.Prototype = {}
Future.Interface = {}

--[[
	Wait for this future to be resolved, this will block the current thread until the future is resolved.
]]
function Future.Prototype.await<T>(self: Future<T>): (FutureStatus, ...T)
	if self.status == "Pending" then
		local thread = coroutine.running()

		table.insert(self._yieldingThreads, thread)

		return coroutine.yield()
	end

	return self.status, table.unpack(self._valueList)
end

--[[
	After the future is resolved, call this callback, this callback will only be
		called if the future is Fulfilled, and not rejected..
]]
function Future.Prototype.after<T>(self: Future<T>, callback: (...T) -> ()): Future<T>
	if self.status == "Fulfilled" then
		task.spawn(callback, table.unpack(self._valueList))

		return self
	end

	table.insert(self._afterCallbacks, callback)

	return self
end

--[[
	Catch any errors that occur in the future, this will only be called if the future is rejected.
]]
function Future.Prototype.catch<T>(self: Future<T>, callback: (string, string) -> ()): Future<T>
	if self.status == "Rejected" then
		task.spawn(callback, self.exception :: string, self.traceback :: string)

		return self
	end

	table.insert(self._catchCallback, callback)

	return self
end

--[[
	Expect the future to resolve, this will throw an error if the future is rejected. (optionally pass
		an error message yourself)
]]
function Future.Prototype.expect<T>(self: Future<T>, errorMessage: string?): ...T
	if self.status == "Pending" then
		self:await()
	end

	assert(self.status == "Fulfilled", errorMessage or `Expected Future to be fulfilled, got ${self.status}`)

	return table.unpack(self._valueList)
end

--[[
	Query the values of the future, the values represent the result of the asynchronous function.
]]
function Future.Prototype.unwrap<T>(self: Future<T>): ...T
	return table.unpack(self._valueList)
end

--[[
	In the case the future has been rejected, or the asynchronous function returned nil - return
		the value passed to this function.
]]
function Future.Prototype.unwrapOr<T>(self: Future<T>, value: T): T
	local status: FutureStatus
	local valueList: { T }

	if self.status == "Pending" then
		self:await()

		status = self.status
		valueList = self._valueList
	else
		status, valueList = self.status, self._valueList
	end

	if status == "Fulfilled" then
		local unwrappedObject = table.remove(valueList, 1) :: T

		if unwrappedObject == nil then
			return value
		end

		return unwrappedObject
	else
		return value
	end
end

--[[
	Execute the future, this will execute the asynchronous function, and resolve/reject the future.
]]
function Future.Prototype.execute<T>(self: Future<T>, ...): Future<T>
	local arguments = table.pack(...)

	task.spawn(function()
		xpcall(function()
			self._valueList = table.pack(self._callback(table.unpack(arguments)))

			self.status = "Fulfilled"

			for _, callback in self._afterCallbacks do
				callback(table.unpack(self._valueList))
			end
		end, function(exception: string)
			self.traceback = debug.traceback(nil, 2)
			self.exception = exception
			self.status = "Rejected"

			if #self._catchCallback == 0 then
				stdio.ewrite(
					`{stdio.style("bold")}{stdio.color("red")}Future encountered an error:\n{stdio.color("blue")}{self.exception}\n`
				)
			else
				for _, callback in self._catchCallback do
					task.spawn(callback, self.exception :: string, self.traceback :: string)
				end
			end
		end)

		for _, callback in self._yieldingThreads do
			task.spawn(
				callback,
				self.status,
				self.status == "Fulfilled" and table.unpack(self._valueList) or self.exception
			)
		end
	end)

	return self
end

--[[
	Constructor for the future object.
]]
function Future.Interface.new<T>(callback: (...any) -> ...T?, ...): Future<T>
	local selfArguments = table.pack(...)
	local self = setmetatable(
		{
			_callback = callback,

			_catchCallback = {},
			_yieldingThreads = {},
			_afterCallbacks = {},
			_valueList = {},

			status = "Pending" :: FutureStatus,
		} :: Future<T>,
		{ __index = Future.Prototype }
	)

	task.defer(function()
		self:execute(table.unpack(selfArguments))
	end)

	return self
end

export type FutureStatus = "Pending" | "Fulfilled" | "Rejected"
export type Future<T> = typeof(Future.Prototype) & {
	_callback: (...T) -> ...any,

	_catchCallback: { (string, string) -> () },
	_yieldingThreads: { thread },
	_afterCallbacks: { (...T) -> () },
	_valueList: { T },

	status: FutureStatus,
	exception: string?,
	traceback: string?,
}

return Future.Interface
