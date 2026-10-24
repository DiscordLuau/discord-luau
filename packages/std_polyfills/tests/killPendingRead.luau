--[=[
	Run as a child process by `spawn.spec.luau`, under Zune's epoll loop on Linux and its kqueue loop on macOS: kills
	a program while a stdout read and the stderr reader both wait on its pipes, waits for the exit, then prints a
	marker and exits on its own, so a completion the kill left behind cannot keep it running.
]=]

local stdPolyfills = require("../src")

local SETTLE_SECONDS = 0.2
local EXIT_POLLS = 300
local POLL_SECONDS = 0.01

local running = stdPolyfills.process.spawn("sleep", { "30" })

stdPolyfills.task.spawn(function()
	running.read(1024)
end)
stdPolyfills.task.wait(SETTLE_SECONDS)

local killed = running.kill()

for _ = 1, EXIT_POLLS do
	if running.exited() then
		break
	end

	stdPolyfills.task.wait(POLL_SECONDS)
end

stdPolyfills.task.wait(SETTLE_SECONDS)
stdPolyfills.stdio.write(`kill with pending reads finished: killed {killed}, exited {running.exited()}\n`)
zune.process.exit(0)
