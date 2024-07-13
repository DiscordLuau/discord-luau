--[=[
	@class Vendor.Signal
	@tag generics T...

	A custom Signal implementation written for Discord Luau.
]=]

--[=[
	@prop _connections { thread }
	@private
	@within Vendor.Signal
]=]

--[=[
	@prop _yielding { thread }
	@private
	@within Vendor.Signal
]=]

local Connection = require("connection")

local vendorTypes = require("@api-types/vendorTypes")

local Signal = {}

Signal.Prototype = {}
Signal.Interface = {}

--[=[
	Invokes all connections.
	
	@method Fire
	@within Vendor.Signal
]=]
function Signal.Prototype.Fire<T...>(self: vendorTypes.Signal<T...>, ...)
	for _, thread in self._connections do
		coroutine.resume(thread, ...)
	end

	for _, thread in self._yielding do
		coroutine.resume(thread, ...)
	end
end

--[=[
	Yields the current thread until the signal is fired.
	
	@yields
	@method Wait
	@within Vendor.Signal
]=]
function Signal.Prototype.Wait<T...>(self: vendorTypes.Signal<T...>, ...)
	local thread = coroutine.running()

	table.insert(self._yielding, thread)

	local index = table.find(self._connections, thread)

	if index then
		table.remove(self._connections, index)
	end

	return coroutine.yield()
end

--[=[
	Connects a function to the signal.
	
	@method Connect
	@param callback (T...) -> ()
	@within Vendor.Signal
	@return Vendor.Connection
]=]
function Signal.Prototype.Connect<T...>(self: vendorTypes.Signal<T...>, callback: (T...) -> ())
	local thread = coroutine.create(function()
		while true do
			local args: { any } = { coroutine.yield() }

			callback(table.unpack(args))

			coroutine.yield()
		end
	end)

	table.insert(self._connections, thread)

	return Connection.new(function()
		local index = table.find(self._connections, thread)

		if index then
			table.remove(self._connections, index)
		end

		coroutine.close(thread)
	end)
end

--[=[
	Create a new Signal.
	
	@function new
	@within Vendor.Signal
	@return Vendor.Signal
]=]
function Signal.Interface.new<T...>(): vendorTypes.Signal<T...>
	return setmetatable(
		{
			_connections = {},
			_yielding = {},
		} :: vendorTypes.Signal<T...>,
		{
			__index = Signal.Prototype,
		}
	)
end

return Signal.Interface
