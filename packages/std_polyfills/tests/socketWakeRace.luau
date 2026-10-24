--[=[
	Run as a child process by `net.spec.luau` with the port of a websocket server that answers every message: a
	message wakes a thread waiting on `socket.next()`, and the thread's owner closes it in the same scheduler step,
	before the deferred wake runs. Prints whether a step was staged that way, then a marker once the scheduler has had
	time to run the wake.
]=]

local stdPolyfills = require("../src")

local MAX_ROUNDS = 5
local SPIN_SECONDS = 0.2
local SETTLE_SECONDS = 0.2

local port = stdPolyfills.process.getArgs()[1]
local socket = stdPolyfills.net.tcpSocket(`ws://127.0.0.1:{port}`)
local waiter = coroutine.create(socket.next)
local staged = false

local function startWaiter()
	local resumed, resumeError = coroutine.resume(waiter)

	assert(resumed, resumeError)
end

local function spin()
	local spinUntil = os.clock() + SPIN_SECONDS

	while os.clock() < spinUntil do
		continue
	end
end

startWaiter()
socket.send("ping")
stdPolyfills.task.wait()

-- Zune reads sockets before it resumes sleeping threads, and runs deferred wakes after both. When the replacement
-- finds the answer already queued, the step that queued it also deferred the closed waiter's wake. The deferred spin
-- blocks the scheduler once this thread's wake is set, so the answer lands unread and the next step reads it while
-- this thread is already due.
for _ = 1, MAX_ROUNDS do
	coroutine.close(waiter)
	waiter = coroutine.create(socket.next)
	startWaiter()

	if coroutine.status(waiter) == "dead" then
		staged = true

		break
	end

	stdPolyfills.task.defer(spin)
	stdPolyfills.task.wait()
end

stdPolyfills.task.wait(SETTLE_SECONDS)
socket.close(1000)
stdPolyfills.stdio.write(`race staged: {staged}\n`)
stdPolyfills.stdio.write("socket wake race finished\n")
