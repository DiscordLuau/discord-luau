--[=[
	@class Vendor.Future
	@tag generics T...
]=]

--[=[
	@prop _threads { thread }
	@within Vendor.Future
]=]

--[=[
	@prop _errorHandlers { thread }
	@within Vendor.Future
]=]

--[=[
	@prop _valueList { any }
	@within Vendor.Future
]=]

--[=[
	@prop isPending boolean
	@within Vendor.Future
]=]

local Task = require("@std-polyfills/task")

local vendorTypes = require("@api-types/vendorTypes")

local Future = {}

Future.Prototype = {}
Future.Interface = {}

function Future.Prototype.after<T...>(self: vendorTypes.Future<T...>, callback: (T...) -> ())
	if self.isPending then
		table.insert(self._threads, coroutine.running())

		callback(coroutine.yield())
	else
		callback(table.unpack(self._valueList))
	end
end

function Future.Prototype.await<T...>(self: vendorTypes.Future<T...>)
	if self.isPending then
		table.insert(self._threads, coroutine.running())

		return coroutine.yield()
	else
		return table.unpack(self._valueList)
	end
end

function Future.Prototype.catch<T...>(self: vendorTypes.Future<T...>, callback: (T...) -> ())
	if self.isPending then
		table.insert(self._errorHandlers, coroutine.running())

		callback(coroutine.yield())
	end
end

--[=[
	Create a new Future.
	
	@function new
	@within Vendor.Future
	@return Vendor.Future
]=]
function Future.Interface.new<T..., A...>(asyncFunction: (A...) -> (), ...): vendorTypes.Future<T...>
	local future = setmetatable(
		{
			_threads = {},
			_errorHandlers = {},
			_valueList = {},

			isPending = true,
		} :: vendorTypes.Future<T...>,
		{
			__index = Future.Prototype,
		}
	)

	local args = { ... }

	Task.defer(function()
		local response = { pcall(asyncFunction, table.unpack(args)) }
		local status = table.remove(response, 1)

		future.isPending = false

		if not status then
			for _, errorHandler in future._errorHandlers do
				coroutine.resume(errorHandler, table.unpack(response))
			end

			if #future._errorHandlers == 0 then
				error(response[1])
			end

			return
		end

		for _, thread in future._threads do
			coroutine.resume(thread, table.unpack(response))
		end
	end)

	return future
end

return Future.Interface
