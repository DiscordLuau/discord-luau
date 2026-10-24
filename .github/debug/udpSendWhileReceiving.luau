-- Sends on UDP sockets that have a receive pending on them, as discord_stub's server and voice's client do, then
-- closes each with its receive pending. Every step logs; one that takes over 5 s is reported and the probe exits 2.
-- Exit 0 at the end means Zune also exited by itself, so no closed socket kept the event loop alive.
local loggerModule = require("../../packages/logger/src")

local STEP_LIMIT_SECONDS = 5
local MAX_PACKET_SIZE = 65536

local net = zune.net
local logger = loggerModule.new("udp-probe", "Debug")
local server = net.createSocket(net.ADDRF.INET, net.SOCKF.DGRAM, net.IPPROTO.UDP)
local client = net.createSocket(net.ADDRF.INET, net.SOCKF.DGRAM, net.IPPROTO.UDP)
local started = os.clock()
local step = "start"
local stepStarted = os.clock()
local finished = false
local serverGot: { string } = {}
local clientGot: { string } = {}
local serverEnded = { value = false }
local clientEnded = { value = false }

local function mark(name: string)
	logger:info(`{string.format("%.3f", os.clock() - started)}s {name}`)
	step = name
	stepStarted = os.clock()
end

local function waitUntil(condition: () -> boolean)
	while not condition() do
		zune.task.wait(0.01)
	end
end

local function receiveLoop(socket: any, name: string, got: { string }, ended: { value: boolean })
	zune.task.spawn(function()
		while true do
			local received, address, packet = pcall(socket.recvMsg, socket, MAX_PACKET_SIZE)

			if not received then
				logger:info(`{name} receive ended: {address}`)
				ended.value = true

				return
			end

			table.insert(got, buffer.tostring(packet))
			logger:info(`{name} got "{buffer.tostring(packet)}" from {address.address}:{address.port}`)
		end
	end)
end

local function main()
	zune.task.spawn(function()
		while not finished do
			zune.task.wait(0.25)

			if not finished and os.clock() - stepStarted > STEP_LIMIT_SECONDS then
				logger:warn(`STUCK for {STEP_LIMIT_SECONDS} s at: {step}`)
				zune.process.exit(2)
			end
		end
	end)

	server:bindIp("127.0.0.1", 0)
	client:bindIp("0.0.0.0", 0)

	local serverPort = server:getName().port
	local clientPort = client:getName().port

	receiveLoop(server, "server", serverGot, serverEnded)
	receiveLoop(client, "client", clientGot, clientEnded)

	mark("client sends hello while both receives wait")
	client:sendMsg(serverPort, "127.0.0.1", "hello")
	mark("client sendMsg returned; waiting for the server to get hello")
	waitUntil(function()
		return #serverGot >= 1
	end)

	mark("server sends audio1 while its own receive waits")
	server:sendMsg(clientPort, "127.0.0.1", "audio1")
	mark("server sendMsg returned; waiting for the client to get audio1")
	waitUntil(function()
		return #clientGot >= 1
	end)

	mark("server sends audio2, then the client sends ping2")
	server:sendMsg(clientPort, "127.0.0.1", "audio2")
	client:sendMsg(serverPort, "127.0.0.1", "ping2")
	mark("both sends returned; waiting for both packets")
	waitUntil(function()
		return #clientGot >= 2 and #serverGot >= 2
	end)

	mark("closing the client while its receive waits")
	client:close()
	mark("client close returned; waiting for its receive to end")
	waitUntil(function()
		return clientEnded.value
	end)

	mark("closing the server while its receive waits")
	server:close()
	mark("server close returned; waiting for its receive to end")
	waitUntil(function()
		return serverEnded.value
	end)

	finished = true
	mark("every step finished; Zune should now exit by itself")
end

main()
