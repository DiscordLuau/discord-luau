--[=[
	@class Emitter
	@__index Prototype

	An emitter that can be used to emit events, this class will be used to push updates from the Discord Websockets
		out to the Consumers of this library.
]=]

local Emitter = {}

Emitter.Interface = {}
Emitter.Prototype = {}

--[=[
	@within Emitter

	Listen to this event, returns a function that can be called to disconnect the listener
]=]
function Emitter.Prototype.listen<T...>(self: Emitter<T...>, callback: (T...) -> ()): () -> ()
	local thread = coroutine.create(function()
		while true do
			callback(coroutine.yield())
		end
	end)

	local status, response = coroutine.resume(thread)

	if not status then
		warn(response)
		print(debug.traceback(thread))
	end

	table.insert(self._connectedThreads, thread)

	return function()
		local index = table.find(self._connectedThreads, thread)

		if index then
			table.remove(self._connectedThreads, index)
		end
	end
end

--[=[
	@within Emitter

	Listen to this event once, this will automatically disconnect after the first invocation
]=]
function Emitter.Prototype.listenOnce<T...>(self: Emitter<T...>, callback: (T...) -> ()): () -> ()
	local disconnect

	disconnect = self:listen(function(...)
		disconnect()

		callback(...)
	end)

	return disconnect
end

--[=[
	@within Emitter

	Wait for this event to be emitted from, returns the result of the emittion
]=]
function Emitter.Prototype.wait<T...>(self: Emitter<T...>): T...
	table.insert(self._yieldingThreads, coroutine.running())

	return coroutine.yield()
end

--[=[
	@within Emitter

	Responsible for invoking all the threads that are listening to this emitter.

	This will additionally resume all the threads that are currently waiting for an event to be emitted.
]=]
function Emitter.Prototype.invoke<T...>(self: Emitter<T...>, ...: any): ()
	local callback = coroutine.wrap(function(...)
		for _, thread in self._yieldingThreads do
			coroutine.resume(thread, ...)
		end

		self._yieldingThreads = {}

		for _, thread in self._connectedThreads do
			coroutine.resume(thread, ...)
		end
	end)

	return callback(...)
end

--[=[
	@within Emitter

	Constructor for the Emitter object, will return a new instance of the Emitter object.
]=]
function Emitter.Interface.new<T...>(): Emitter<T...>
	return setmetatable(
		{
			_yieldingThreads = {},
			_connectedThreads = {},
		} :: Emitter<T...>,
		{
			__index = Emitter.Prototype,
		}
	)
end

export type Emitter<T...> = typeof(Emitter.Prototype) & {
	_yieldingThreads: { thread },
	_connectedThreads: { thread },
}

return Emitter.Interface
