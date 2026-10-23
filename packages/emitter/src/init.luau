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

local function runCallback(emitter: any, callback: (...any) -> (), arguments: { n: number, [number]: any })
	local succeeded, callbackError = xpcall(function()
		callback(table.unpack(arguments, 1, arguments.n))
	end, function(errorMessage)
		return debug.traceback(errorMessage, 2)
	end)

	if not succeeded then
		local invokeTrace = emitter.lastInvokeTrace
		local message = `listener callback errored:\n{callbackError}`

		if invokeTrace then
			message ..= `\n\ninvoke site:\n{invokeTrace}`
		end

		logger:warn(message)
	end
end

--[=[
	@within Emitter

	Listen to this event, returns a function that can be called to disconnect the listener.

	The callback may yield. An event that arrives while the callback is still running (yielded) is handled
	in a new thread with its own arguments, so a slow listener never receives another event's arguments.
]=]
function Emitter.Prototype.listen<T...>(self: Emitter<T...>, callback: (T...) -> ()): () -> ()
	local thread: thread

	thread = coroutine.create(function()
		while true do
			local arguments = table.pack(coroutine.yield())

			self.busyListeners[thread] = true
			runCallback(self, callback :: any, arguments)
			self.busyListeners[thread] = nil
		end
	end)

	local resumed, resumeError = coroutine.resume(thread)

	if not resumed then
		logger:warn(`failed to initialise listener thread: {resumeError}`)
	end

	table.insert(self.connectedThreads, thread)
	self.listenerCallbacks[thread] = callback :: any

	return function()
		self:removeListener(thread)
	end
end

--[=[
	@within Emitter
	@private

	Forgets a listener thread: it receives no further events.
]=]
function Emitter.Prototype.removeListener<T...>(self: Emitter<T...>, thread: thread)
	local index = table.find(self.connectedThreads, thread)

	if index then
		table.remove(self.connectedThreads, index)
	end

	self.listenerCallbacks[thread] = nil
	self.busyListeners[thread] = nil
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
	table.insert(self.yieldingThreads, coroutine.running())

	return coroutine.yield()
end

--[=[
	@within Emitter

	Responsible for invoking all the threads that are listening to this emitter.

	This will additionally resume all the threads that are currently waiting for an event to be emitted.
]=]
function Emitter.Prototype.invoke<T...>(self: Emitter<T...>, ...: T...): ()
	local waitingThreads = self.yieldingThreads

	self.lastInvokeTrace = debug.traceback()
	self.yieldingThreads = {}

	for _, thread in waitingThreads do
		if coroutine.status(thread) == "dead" then
			continue
		end

		local resumed, resumeError = coroutine.resume(thread, ...)

		if not resumed then
			logger:warn(`failed to resume waiting thread: {resumeError}\n\ninvoke site:\n{self.lastInvokeTrace}`)
		end
	end

	for _, thread in table.clone(self.connectedThreads) do
		local callback = self.listenerCallbacks[thread]
		local threadStatus = coroutine.status(thread)

		if not callback then
			continue
		end

		if threadStatus == "dead" then
			self:removeListener(thread)

			continue
		end

		if self.busyListeners[thread] then
			local resumed, resumeError =
				coroutine.resume(coroutine.create(runCallback), self, callback, table.pack(...))

			if not resumed then
				logger:warn(
					`failed to run busy listener in a new thread: {resumeError}\n\ninvoke site:\n{self.lastInvokeTrace}`
				)
			end

			continue
		end

		local resumed, resumeError = coroutine.resume(thread, ...)

		if not resumed then
			logger:warn(`failed to resume connected thread: {resumeError}\n\ninvoke site:\n{self.lastInvokeTrace}`)
			self:removeListener(thread)
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
			yieldingThreads = {},
			connectedThreads = {},
			listenerCallbacks = {},
			busyListeners = {},
		} :: Emitter<T...>,
		{
			__index = Emitter.Prototype,
		}
	)
end

export type Emitter<T...> = typeof(Emitter.Prototype) & {
	yieldingThreads: { thread },
	connectedThreads: { thread },
	lastInvokeTrace: string?,
	listenerCallbacks: { [thread]: (...any) -> () },
	busyListeners: { [thread]: boolean },
}

return Emitter.Interface
