--[[
	A wrapper for Asynchronous functions, this is a middle ground between a Promise + Future, where the goals were:
		- Async should be immutable
		- Async should be immediate.
		- Async should enable you to error handle.
]]

local stdPolyfills = require("../lune_packages/std_polyfills")

local task = stdPolyfills.task
local stdio = stdPolyfills.stdio

local Async = {}

Async.Prototype = {}
Async.Interface = {}

--[[
	Wait for this future to be resolved, this will block the current thread until the future is resolved.
]]
function Async.Prototype.await<T>(self: Async<T>): (FutureStatus, ...T)
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
function Async.Prototype.after<T>(self: Async<T>, callback: (...T) -> ()): Async<T>
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
function Async.Prototype.catch<T>(self: Async<T>, callback: (string, string) -> ()): Async<T>
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
function Async.Prototype.expect<T>(self: Async<T>, errorMessage: string?): ...T
	if self.status == "Pending" then
		self:await()
	end

	assert(self.status == "Fulfilled", errorMessage or `Expected Async to be fulfilled, got ${self.status}`)

	return table.unpack(self._valueList)
end

--[[
	Query the values of the future, the values represent the result of the asynchronous function.
]]
function Async.Prototype.unwrap<T>(self: Async<T>): ...T
	return table.unpack(self._valueList)
end

--[[
	In the case the future has been rejected, or the asynchronous function returned nil - return
		the value passed to this function.
]]
function Async.Prototype.unwrapOr<T>(self: Async<T>, value: T): T
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
function Async.Prototype.execute<T>(self: Async<T>, ...): Async<T>
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
					`{stdio.style("bold")}{stdio.color("red")}Async encountered an error:\n{stdio.color("blue")}{self.exception}\n`
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
function Async.Interface.new<T>(callback: (...any) -> ...T?, ...): Async<T>
	local selfArguments = table.pack(...)
	local self = setmetatable(
		{
			_callback = callback,

			_catchCallback = {},
			_yieldingThreads = {},
			_afterCallbacks = {},
			_valueList = {},

			status = "Pending" :: FutureStatus,
		} :: Async<T>,
		{ __index = Async.Prototype }
	)

	task.defer(function()
		self:execute(table.unpack(selfArguments))
	end)

	return self
end

export type FutureStatus = "Pending" | "Fulfilled" | "Rejected"
export type Async<T> = typeof(Async.Prototype) & {
	_callback: (...T) -> ...any,

	_catchCallback: { (string, string) -> () },
	_yieldingThreads: { thread },
	_afterCallbacks: { (...T) -> () },
	_valueList: { T },

	status: FutureStatus,
	exception: string?,
	traceback: string?,
}

return Async.Interface
