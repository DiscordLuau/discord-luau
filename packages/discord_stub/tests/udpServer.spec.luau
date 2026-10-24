local frktest = require("../../../luau_packages/frktest")

local discordStub = require("../src/init")

local UNSET_ADDRESS: NetworkAddress = { family = 0, port = 0, address = "::" }
local CLIENT_ADDRESS: NetworkAddress = { family = 2, port = 50000, address = "127.0.0.1" }
local KEEPALIVE_SIZE = 5
local OVERLAPPING_SENDS = 8

local test = frktest.test
local check = frktest.assert.check

local function openClient(port: number): NetworkSocket
	local client = zune.net.createSocket(zune.net.ADDRF.INET, zune.net.SOCKF.DGRAM, zune.net.IPPROTO.UDP)

	client:connect("127.0.0.1", port)

	return client
end

local function bindClient(): NetworkSocket
	local client = zune.net.createSocket(zune.net.ADDRF.INET, zune.net.SOCKF.DGRAM, zune.net.IPPROTO.UDP)

	client:bindIp("127.0.0.1", 0)

	return client
end

local function receiveMessagesInto(client: NetworkSocket, replies: { buffer })
	zune.task.spawn(function()
		while client:isOpen() do
			local received, _address, reply = pcall(client.recvMsg, client, 65536)

			if not received then
				break
			end

			table.insert(replies, reply)
		end
	end)
end

local function receiveInto(client: NetworkSocket, replies: { buffer })
	zune.task.spawn(function()
		while client:isOpen() do
			local received, reply = pcall(client.recv, client, 65536)

			if not received then
				break
			end

			table.insert(replies, reply)
		end
	end)
end

local function discoveryRequest(ssrc: number): buffer
	local request = buffer.create(74)

	buffer.writeu8(request, 1, 0x01)
	buffer.writeu8(request, 3, 70)
	buffer.writeu32(request, 4, bit32.byteswap(ssrc))

	return request
end

local function keepalivePacket(): buffer
	local packet = buffer.create(KEEPALIVE_SIZE)

	buffer.writeu8(packet, 0, 0xC9)
	buffer.writeu8(packet, 4, 7)

	return packet
end

--[=[
	Runs the server's receive loop over a socket that hands out `receives` in order, then ends the loop the way `stop`
	does, and returns every datagram the server sent. A real socket cannot receive a Windows-only report on demand.
]=]
local function runScriptedReceives(
	udp: discordStub.UdpServer,
	receives: { () -> (NetworkAddress, buffer) }
): { SentDatagram }
	local realSocket = udp.socket :: NetworkSocket
	local sent: { SentDatagram } = {}
	local scripted = {}

	function scripted.recvMsg(_socket: any, _maxSize: number?): (NetworkAddress, buffer)
		local receive = table.remove(receives, 1)

		if not receive then
			udp.socket = nil
			error("Canceled", 0)
		end

		return receive()
	end

	function scripted.sendMsg(_socket: any, port: number, address: string, data: buffer)
		table.insert(sent, { address = address, port = port, length = buffer.len(data) })
	end

	udp.socket = scripted :: any
	realSocket:close()
	udp:receiveLoop(scripted :: any)

	return sent
end

type SentDatagram = { address: string, port: number, length: number }

return function()
	test.suite("discord_stub udp server", function()
		test.case(
			"IP discovery is answered with type 2, length 70, the same ssrc, the null-padded address and the client's port",
			function()
				local stub = discordStub.new({ clock = "virtual" })
				local udp = discordStub.UdpServer.new()
				local client = openClient(udp.port)
				local replies = {}

				receiveInto(client, replies)
				client:send(discoveryRequest(0x01020304))

				check.is_true(stub.clock:waitFor(function()
					return #replies == 1
				end, 30))

				local reply = replies[1]
				local clientPort = client:getName().port

				check.equal(buffer.len(reply), 74)
				check.equal(buffer.readu8(reply, 0), 0x00)
				check.equal(buffer.readu8(reply, 1), 0x02)
				check.equal(buffer.readu8(reply, 2), 0x00)
				check.equal(buffer.readu8(reply, 3), 70)
				check.equal(bit32.byteswap(buffer.readu32(reply, 4)), 0x01020304)
				check.equal(buffer.readstring(reply, 8, 9), "127.0.0.1")
				check.equal(buffer.readstring(reply, 17, 55), string.rep("\0", 55))
				check.equal(buffer.readu8(reply, 72) * 256 + buffer.readu8(reply, 73), clientPort)
				check.equal(udp.clientAddress, "127.0.0.1")
				check.equal(udp.clientPort, clientPort)
				check.equal(#udp.packets, 0)

				client:close()
				udp:stop()
				stub:stop()
			end
		)

		test.case("a keepalive is echoed back unchanged and is not recorded", function()
			local stub = discordStub.new({ clock = "virtual" })
			local udp = discordStub.UdpServer.new()
			local client = openClient(udp.port)
			local replies = {}
			local keepalive = buffer.create(5)

			buffer.writeu8(keepalive, 0, 0xC9)
			buffer.writeu8(keepalive, 4, 7)
			receiveInto(client, replies)
			client:send(keepalive)

			check.is_true(stub.clock:waitFor(function()
				return #replies == 1
			end, 30))

			check.equal(buffer.tostring(replies[1]), buffer.tostring(keepalive))
			check.equal(#udp.packets, 0)

			client:close()
			udp:stop()
			stub:stop()
		end)

		test.case("RTP packets are recorded and send reaches the client they came from", function()
			local stub = discordStub.new({ clock = "virtual" })
			local udp = discordStub.UdpServer.new()
			local client = openClient(udp.port)
			local replies = {}
			local rtpPacket = buffer.create(16)
			local sentBeforeClient = pcall(function()
				udp:send(buffer.create(1))
			end)

			check.is_false(sentBeforeClient)

			buffer.writeu8(rtpPacket, 0, 0x80)
			buffer.writeu8(rtpPacket, 1, 0x78)
			buffer.writestring(rtpPacket, 12, "opus")
			receiveInto(client, replies)
			client:send(rtpPacket)

			check.is_true(stub.clock:waitFor(function()
				return #udp.packets == 1
			end, 30))

			check.equal(buffer.tostring(udp.packets[1]), buffer.tostring(rtpPacket))
			check.equal(#replies, 0)

			udp:send(buffer.fromstring("server audio"))

			check.is_true(stub.clock:waitFor(function()
				return #replies == 1
			end, 30))

			check.equal(buffer.tostring(replies[1]), "server audio")

			client:close()
			udp:stop()
			stub:stop()
		end)

		test.case("sends that overlap all return, and their packets reach the client in order", function()
			local stub = discordStub.new({ clock = "virtual" })
			local udp = discordStub.UdpServer.new()
			local client = bindClient()
			local replies: { buffer } = {}
			local expected: { string } = {}
			local returned = 0

			receiveMessagesInto(client, replies)
			client:sendMsg(udp.port, "127.0.0.1", keepalivePacket())

			check.is_true(stub.clock:waitFor(function()
				return #replies == 1
			end, 30))

			for index = 1, OVERLAPPING_SENDS do
				table.insert(expected, `packet {index}`)
				zune.task.spawn(function()
					udp:send(buffer.fromstring(`packet {index}`))
					returned += 1
				end)
			end

			stub.clock:waitFor(function()
				return returned == OVERLAPPING_SENDS and #replies == OVERLAPPING_SENDS + 1
			end, 30)

			local arrived: { string } = {}

			for index = 2, #replies do
				table.insert(arrived, buffer.tostring(replies[index]))
			end

			client:close()
			udp:stop()
			stub:stop()

			check.equal(returned, OVERLAPPING_SENDS)
			check.equal(table.concat(arrived, ", "), table.concat(expected, ", "))
		end)

		test.case("a send waiting for its turn when the server stops fails at once", function()
			local stub = discordStub.new({ clock = "virtual" })
			local udp = discordStub.UdpServer.new()
			local client = bindClient()
			local replies: { buffer } = {}
			local waiting = { done = false, failed = false }

			receiveMessagesInto(client, replies)
			client:sendMsg(udp.port, "127.0.0.1", keepalivePacket())

			check.is_true(stub.clock:waitFor(function()
				return #replies == 1
			end, 30))

			zune.task.spawn(function()
				pcall(udp.send, udp, buffer.fromstring("in flight"))
			end)
			zune.task.spawn(function()
				local sent = pcall(udp.send, udp, buffer.fromstring("waiting"))

				waiting.done = true
				waiting.failed = not sent
			end)
			udp:stop()
			stub.clock:waitFor(function()
				return waiting.done
			end, 30)
			client:close()
			stub:stop()

			check.is_true(waiting.done)
			check.is_true(waiting.failed)
		end)

		test.case("stop cancels the pending receive and ends the loop without an error, and is safe twice", function()
			local stub = discordStub.new({ clock = "virtual" })
			local udp = discordStub.UdpServer.new()
			local stopped = 0

			udp.onStop = function()
				stopped += 1
			end

			check.is_true(udp.receiving)

			udp:stop()

			check.is_true(stub.clock:waitFor(function()
				return not udp.receiving
			end, 30))

			udp:stop()

			check.equal(udp.socket, nil)
			check.equal(#udp.errors, 0)
			check.equal(stopped, 2)

			local sentAfterStop = pcall(function()
				udp:send(buffer.create(1))
			end)

			check.is_false(sentAfterStop)

			stub:stop()
		end)

		test.case("ignoreDiscovery drops that many discovery requests, then answers again", function()
			local stub = discordStub.new({ clock = "virtual" })
			local udp = discordStub.UdpServer.new()
			local client = openClient(udp.port)
			local replies = {}

			udp.ignoreDiscovery = 2
			receiveInto(client, replies)
			client:send(discoveryRequest(7))
			client:send(discoveryRequest(7))

			check.is_false(stub.clock:waitFor(function()
				return #replies > 0
			end, 2))

			client:send(discoveryRequest(7))

			check.is_true(stub.clock:waitFor(function()
				return #replies == 1
			end, 30))
			check.equal(udp.ignoreDiscovery, 0)

			client:close()
			udp:stop()
			stub:stop()
		end)

		test.case("a ConnectionResetByPeer receive, Windows' report of a client that has gone, is skipped", function()
			local udp = discordStub.UdpServer.new()
			local sent = runScriptedReceives(udp, {
				function(): (NetworkAddress, buffer)
					error("ConnectionResetByPeer", 0)
				end,
				function()
					return CLIENT_ADDRESS, keepalivePacket()
				end,
			})

			check.table.equal(udp.errors, {})
			check.table.equal(sent, { { address = "127.0.0.1", port = 50000, length = KEEPALIVE_SIZE } })
			check.is_false(udp.receiving)
		end)

		test.case("an empty datagram from no address, which Zune on Windows can return, is skipped", function()
			local udp = discordStub.UdpServer.new()
			local sent = runScriptedReceives(udp, {
				function()
					return UNSET_ADDRESS, buffer.create(0)
				end,
				function()
					return CLIENT_ADDRESS, keepalivePacket()
				end,
			})

			check.table.equal(udp.errors, {})
			check.table.equal(sent, { { address = "127.0.0.1", port = 50000, length = KEEPALIVE_SIZE } })
			check.equal(udp.clientAddress, "127.0.0.1")
			check.equal(udp.clientPort, 50000)
		end)
	end)
end
