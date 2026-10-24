local frktest = require("../../../luau_packages/frktest")

local stdPolyfills = require("../src")

local LOOPBACK_ADDRESS = "127.0.0.1"
local REQUEST = "request"
local MAX_PACKET_SIZE = 65536
local READ_TIMEOUT_SECONDS = 5
local POLL_SECONDS = 0.01
local OVERLAPPING_SENDS = 8

local test = frktest.test
local check = frktest.assert.check

if stdPolyfills.runtime.getRuntime() ~= "Zune" then
	return function()
		test.skip.suite("Zune UDP adapter", function() end)
	end
end

local function bindPeer(): NetworkSocket
	local peer = zune.net.createSocket(zune.net.ADDRF.INET, zune.net.SOCKF.DGRAM, zune.net.IPPROTO.UDP)

	peer:bindIp(LOOPBACK_ADDRESS, 0)

	return peer
end

local function openSocket(peer: NetworkSocket): stdPolyfills.UdpSocket
	local opened, udpSocket = pcall(stdPolyfills.net.udpSocket, LOOPBACK_ADDRESS, peer:getName().port)

	if not opened then
		peer:close()
	end

	assert(opened, `the UDP socket did not open: {udpSocket}`)

	return udpSocket
end

local function answerFirstDatagram(peer: NetworkSocket, answer: (address: NetworkAddress) -> ())
	stdPolyfills.task.spawn(function()
		local received, address, request = pcall(peer.recvMsg, peer, MAX_PACKET_SIZE)

		if received and buffer.tostring(request) == REQUEST then
			answer(address)
		end
	end)
end

local function readOnce(udpSocket: stdPolyfills.UdpSocket): Read
	local read: Read = { done = false }

	stdPolyfills.task.spawn(function()
		local succeeded, response = pcall(udpSocket.next)

		read.done = true
		read.response = if succeeded then response else nil
		read.failure = if succeeded then nil else tostring(response)
	end)

	return read
end

local function waitUntil(condition: () -> boolean)
	local deadline = os.clock() + READ_TIMEOUT_SECONDS

	while not condition() and os.clock() < deadline do
		stdPolyfills.task.wait(POLL_SECONDS)
	end
end

local function waitForRead(read: Read)
	waitUntil(function()
		return read.done
	end)
end

type Read = { done: boolean, response: string?, failure: string? }

return function()
	test.suite("Zune UDP adapter", function()
		test.case("a socket reads its peer's reply when the read started before the first send", function()
			local peer = bindPeer()
			local udpSocket = openSocket(peer)
			local read = readOnce(udpSocket)

			answerFirstDatagram(peer, function(address)
				peer:sendMsg(address.port, address.address, "reply")
			end)
			udpSocket.send(buffer.fromstring(REQUEST))
			waitForRead(read)
			udpSocket.close()
			peer:close()

			check.equal(read.failure, nil)
			check.equal(read.response, "reply")
		end)

		test.case("a socket skips datagrams from anyone but its peer", function()
			local peer = bindPeer()
			local stranger = bindPeer()
			local udpSocket = openSocket(peer)
			local read = readOnce(udpSocket)

			answerFirstDatagram(peer, function(address)
				stranger:sendMsg(address.port, address.address, "stranger")
				peer:sendMsg(address.port, address.address, "reply")
			end)
			udpSocket.send(buffer.fromstring(REQUEST))
			waitForRead(read)
			udpSocket.close()
			stranger:close()
			peer:close()

			check.equal(read.failure, nil)
			check.equal(read.response, "reply")
		end)

		test.case("sends that overlap all return, and their datagrams reach the peer in order", function()
			local peer = bindPeer()
			local udpSocket = openSocket(peer)
			local received: { string } = {}
			local expected: { string } = {}
			local returned = 0

			stdPolyfills.task.spawn(function()
				while #received < OVERLAPPING_SENDS do
					local succeeded, _address, datagram = pcall(peer.recvMsg, peer, MAX_PACKET_SIZE)

					if not succeeded then
						break
					end

					table.insert(received, buffer.tostring(datagram))
				end
			end)

			for index = 1, OVERLAPPING_SENDS do
				table.insert(expected, `datagram {index}`)
				stdPolyfills.task.spawn(function()
					udpSocket.send(buffer.fromstring(`datagram {index}`))
					returned += 1
				end)
			end

			waitUntil(function()
				return returned == OVERLAPPING_SENDS and #received == OVERLAPPING_SENDS
			end)
			udpSocket.close()
			peer:close()

			check.equal(returned, OVERLAPPING_SENDS)
			check.equal(table.concat(received, ", "), table.concat(expected, ", "))
		end)
	end)
end
