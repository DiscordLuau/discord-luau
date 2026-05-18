--[=[
	@class Emitter
	@__index Prototype

	An emitter that can be used to emit events, this class will be used to push updates from the Discord Websockets
		out to the Consumers of this library.
]=]

local Logger = require("./luau_packages/logger")

local logger = Logger.new("Emitter")

local Emitter = {}

Emitter.Interface = {}
Emitter.Prototype = {}

--[=[
	@within Emitter

	Listen to this event, returns a function that can be called to disconnect the listener
]=]
function Emitter.Prototype.listen<T...>(self: Emitter<T...>, callback: (T...) -> ()): () -> ()
	local emitterRef = self

	local thread = coroutine.create(function()
		while true do
			local args = table.pack(coroutine.yield())

			local ok, err = xpcall(function()
				(callback :: any)(table.unpack(args, 1, args.n))
			end, function(errMsg)
				return debug.traceback(errMsg, 2)
			end)

			if not ok then
				local invokeTrace = emitterRef._lastInvokeTrace
				local message = `listener callback errored:\n{err}`

				if invokeTrace then
					message ..= `\n\ninvoke site:\n{invokeTrace}`
				end

				logger:warn(message)
			end
		end
	end)

	local status, err = coroutine.resume(thread)

	if not status then
		logger:warn(`failed to initialise listener thread: {err}`)
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
function Emitter.Prototype.invoke<T...>(self: Emitter<T...>, ...: T...): ()
	self._lastInvokeTrace = debug.traceback()

	for _, thread in self._yieldingThreads do
		if coroutine.status(thread) == "dead" then
			continue
		end

		local status, response = coroutine.resume(thread, ...)

		if not status then
			logger:warn(`failed to resume yielding thread: {response}\n\ninvoke site:\n{self._lastInvokeTrace}`)
		end
	end

	self._yieldingThreads = {}

	for i = #self._connectedThreads, 1, -1 do
		local thread = self._connectedThreads[i]
		local threadStatus = coroutine.status(thread)

		if threadStatus == "dead" then
			table.remove(self._connectedThreads, i)
			continue
		end

		if threadStatus == "normal" then
			continue
		end

		local status, response = coroutine.resume(thread, ...)

		if not status then
			logger:warn(`failed to resume connected thread: {response}\n\ninvoke site:\n{self._lastInvokeTrace}`)
			table.remove(self._connectedThreads, i)
		end
	end
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
	_lastInvokeTrace: string?,
}

return Emitter.Interface
