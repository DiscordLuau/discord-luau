--[=[
	Run as a child process by `net.spec.luau`: closes a thread that is waiting on `socket.next()`, then closes
	the socket, and prints a marker once the scheduler has had time to run anything the close deferred.
]=]

local stdPolyfills = require("../src")

local SETTLE_SECONDS = 0.2

local server = zune.net.http.serve({
	port = 0,
	address = "127.0.0.1",
	request = function()
		return { status_code = 404, body = "" }
	end,
	websocket = {
		upgrade = function()
			return true
		end,
	},
})
local socket = stdPolyfills.net.tcpSocket(`ws://127.0.0.1:{server:getPort()}`)
local waiter = coroutine.create(function()
	socket.next()
end)

local resumed, resumeError = coroutine.resume(waiter)

assert(resumed, resumeError)

coroutine.close(waiter)
socket.close(1000)
stdPolyfills.task.wait(SETTLE_SECONDS)
server:stop()

stdPolyfills.stdio.write("socket teardown finished\n")
