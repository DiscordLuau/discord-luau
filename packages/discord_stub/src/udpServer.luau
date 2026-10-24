--[=[
	@class DiscordStub.UdpServer
	@__index Prototype

	A localhost voice UDP server: it answers IP discovery, echoes keepalives and records every RTP packet for the test
	to assert on. `new` binds it to `127.0.0.1` with an ephemeral port and starts a receive loop that yields to the
	scheduler while it waits for a packet.
]=]

--[=[
	@prop socket NetworkSocket?
	@within DiscordStub.UdpServer
	The Zune UDP socket, nil after the server stops.
]=]

--[=[
	@prop port number
	@within DiscordStub.UdpServer
	The ephemeral port the server bound to on `127.0.0.1`.
]=]

--[=[
	@prop packets { buffer }
	@within DiscordStub.UdpServer
	Every RTP packet the server received, oldest first. IP discovery requests and keepalives are not recorded.
]=]

--[=[
	@prop clientAddress string?
	@within DiscordStub.UdpServer
	The address the latest packet came from, nil before the first packet.
]=]

--[=[
	@prop clientPort number?
	@within DiscordStub.UdpServer
	The port the latest packet came from, nil before the first packet.
]=]

--[=[
	@prop receiving boolean
	@within DiscordStub.UdpServer
	True while the receive loop runs; false once `stop` has ended it.
]=]

--[=[
	@prop errors { string }
	@within DiscordStub.UdpServer
	Every error the receive loop raised, other than the cancelled receive that `stop` causes and Windows' report of a
	client that has gone.
]=]

--[=[
	@prop ignoreDiscovery number
	@within DiscordStub.UdpServer
	How many of the next IP discovery requests to drop without a reply.
]=]

--[=[
	@prop onStop function?
	@within DiscordStub.UdpServer
	Called with the handle after it stops.
]=]

--[=[
	@prop sendingThread thread?
	@within DiscordStub.UdpServer
	@private
	The thread whose send has the socket, nil while no send is in flight.
]=]

--[=[
	@prop waitingSends { thread }
	@within DiscordStub.UdpServer
	@private
	Threads waiting for their turn to send, oldest first.
]=]

local MAX_PACKET_SIZE = 65536
local DISCOVERY_PACKET_SIZE = 74
local DISCOVERY_REQUEST_TYPE = 0x0001
local DISCOVERY_RESPONSE_TYPE = 0x0002
local DISCOVERY_MESSAGE_LENGTH = 70
local DISCOVERY_SSRC_OFFSET = 4
local DISCOVERY_ADDRESS_OFFSET = 8
local DISCOVERY_ADDRESS_SIZE = 64
local DISCOVERY_PORT_OFFSET = 72
local RTP_VERSION = 2
local UNREACHABLE_CLIENT_ERROR = "ConnectionResetByPeer"

local UdpServer = {}

UdpServer.Interface = {}
UdpServer.Prototype = {}

local function readBigEndian16(packet: buffer, offset: number): number
	return buffer.readu8(packet, offset) * 256 + buffer.readu8(packet, offset + 1)
end

local function writeBigEndian16(packet: buffer, offset: number, value: number)
	buffer.writeu8(packet, offset, bit32.rshift(value, 8))
	buffer.writeu8(packet, offset + 1, bit32.band(value, 0xFF))
end

--[=[
	@within DiscordStub.UdpServer
	@private

	Waits until no other send has the socket, then gives it to `thread`. On macOS Zune keeps one pending write per
	socket, so a send that overlaps another replaces it, and the first is never sent and never returns.
]=]
function UdpServer.Prototype.waitForSendTurn(self: UdpServer, thread: thread)
	local sendingThread = self.sendingThread

	if sendingThread and coroutine.status(sendingThread) ~= "dead" then
		table.insert(self.waitingSends, thread)
		print(`[trace {string.format("%.3f", os.clock())}] stub send waits for its turn ({#self.waitingSends} waiting)`)
		coroutine.yield()
		print(`[trace {string.format("%.3f", os.clock())}] stub send got its turn`)
	end

	self.sendingThread = thread
end

--[=[
	@within DiscordStub.UdpServer
	@private

	Gives the socket to the oldest waiting send, passing over a thread its owner closed while it waited.
]=]
function UdpServer.Prototype.startNextSend(self: UdpServer)
	local nextThread = table.remove(self.waitingSends, 1)

	self.sendingThread = nextThread

	if nextThread then
		zune.task.defer(function()
			print(`[trace {string.format("%.3f", os.clock())}] stub turn handed over, waiter status {coroutine.status(nextThread)}`)
			if coroutine.status(nextThread) == "suspended" then
				zune.task.spawn(nextThread)
			elseif self.sendingThread == nextThread then
				self:startNextSend()
			end
		end)
	end
end

--[=[
	@within DiscordStub.UdpServer

	Sends one packet to the client the latest packet came from, after any send already in flight. Errors before any
	client has sent a packet or after the server stops.
]=]
function UdpServer.Prototype.send(self: UdpServer, packet: buffer)
	local socket = self.socket
	local clientAddress = self.clientAddress
	local clientPort = self.clientPort
	local thread = coroutine.running()

	assert(socket, "discord_stub: the UDP server has stopped")
	assert(clientAddress and clientPort, "discord_stub: no client has sent the UDP server a packet yet")

	self:waitForSendTurn(thread)

	print(`[trace {string.format("%.3f", os.clock())}] stub sendMsg {buffer.len(packet)}B to {clientAddress}:{clientPort}`)
	local sent, sendError = pcall(socket.sendMsg, socket, clientPort, clientAddress, packet)
	print(`[trace {string.format("%.3f", os.clock())}] stub sendMsg returned ok={sent}`)

	if self.sendingThread == thread then
		self:startNextSend()
	end

	if not sent then
		error(sendError, 0)
	end
end

--[=[
	@within DiscordStub.UdpServer
	@private

	Answers an IP discovery request with the address and port the request came from, the way Discord reports a
	client's external address.
]=]
function UdpServer.Prototype.answerDiscovery(self: UdpServer, address: NetworkAddress, request: buffer)
	local response = buffer.create(DISCOVERY_PACKET_SIZE)
	local reportedAddress = string.sub(address.address, 1, DISCOVERY_ADDRESS_SIZE - 1)

	writeBigEndian16(response, 0, DISCOVERY_RESPONSE_TYPE)
	writeBigEndian16(response, 2, DISCOVERY_MESSAGE_LENGTH)
	buffer.copy(response, DISCOVERY_SSRC_OFFSET, request, DISCOVERY_SSRC_OFFSET, 4)
	buffer.writestring(response, DISCOVERY_ADDRESS_OFFSET, reportedAddress)
	writeBigEndian16(response, DISCOVERY_PORT_OFFSET, address.port)

	self:send(response)
end

--[=[
	@within DiscordStub.UdpServer
	@private

	Answers one packet. A 74-byte packet of type 0x0001 is an IP discovery request; a packet whose top two bits carry
	RTP version 2 is recorded in `packets`; anything else is a keepalive and is echoed back unchanged.
]=]
function UdpServer.Prototype.handlePacket(self: UdpServer, address: NetworkAddress, packet: buffer)
	local length = buffer.len(packet)
	local isDiscovery = length == DISCOVERY_PACKET_SIZE and readBigEndian16(packet, 0) == DISCOVERY_REQUEST_TYPE
	local isRtp = length > 0 and bit32.rshift(buffer.readu8(packet, 0), 6) == RTP_VERSION

	self.clientAddress = address.address
	self.clientPort = address.port

	if isDiscovery and self.ignoreDiscovery > 0 then
		self.ignoreDiscovery -= 1
	elseif isDiscovery then
		self:answerDiscovery(address, packet)
	elseif isRtp then
		table.insert(self.packets, packet)
	else
		self:send(packet)
	end
end

--[=[
	@within DiscordStub.UdpServer
	@private

	Receives packets until `stop` replaces the socket. A receive error while the server still runs ends the loop and
	lands in `errors`; an error answering one packet lands in `errors` and the loop carries on. Windows' report of a
	client that has gone (`ConnectionResetByPeer`) and an empty datagram are skipped.
]=]
function UdpServer.Prototype.receiveLoop(self: UdpServer, socket: NetworkSocket)
	self.receiving = true

	while self.socket == socket do
		print(`[trace {string.format("%.3f", os.clock())}] stub recvMsg waiting`)
		local received, address, packet = pcall(socket.recvMsg, socket, MAX_PACKET_SIZE)
		print(`[trace {string.format("%.3f", os.clock())}] stub recvMsg returned ok={received} {if received then `{buffer.len(packet)}B` else tostring(address)}`)

		-- On Windows a send to a client that has gone fails the next receive with this error. Zune 0.5.9 on Windows can
		-- also complete a receive with an empty datagram from no address, which has nothing to answer.
		if not received and tostring(address) == UNREACHABLE_CLIENT_ERROR then
			continue
		end

		if received and buffer.len(packet) == 0 then
			continue
		end

		if not received then
			if self.socket == socket then
				table.insert(self.errors, tostring(address))
			end

			break
		end

		local handled, handleError = pcall(function()
			self:handlePacket(address, packet)
		end)

		if not handled then
			table.insert(self.errors, tostring(handleError))
		end
	end

	self.receiving = false
end

--[=[
	@within DiscordStub.UdpServer

	Closes the socket, which cancels the pending receive and ends the receive loop. Safe to call twice.
]=]
function UdpServer.Prototype.stop(self: UdpServer)
	local socket = self.socket

	self.socket = nil

	if socket then
		socket:close()
	end

	if self.onStop then
		self.onStop(self)
	end
end

--[=[
	@within DiscordStub.UdpServer

	Binds a UDP socket on `127.0.0.1` with an ephemeral port and starts the receive loop.
]=]
function UdpServer.Interface.new(settings: { onStop: ((server: UdpServer) -> ())? }?): UdpServer
	local socket = zune.net.createSocket(zune.net.ADDRF.INET, zune.net.SOCKF.DGRAM, zune.net.IPPROTO.UDP)

	socket:bindIp("127.0.0.1", 0)

	local self = setmetatable(
		{
			port = socket:getName().port,
			packets = {},
			receiving = false,
			errors = {},
			ignoreDiscovery = 0,
			onStop = if settings then settings.onStop else nil,
			waitingSends = {},
		} :: UdpServer,
		{ __index = UdpServer.Prototype }
	)

	self.socket = socket

	zune.task.spawn(function()
		self:receiveLoop(socket)
	end)

	return self
end

export type UdpServer = typeof(UdpServer.Prototype) & {
	socket: NetworkSocket?,
	port: number,
	packets: { buffer },
	clientAddress: string?,
	clientPort: number?,
	receiving: boolean,
	errors: { string },
	ignoreDiscovery: number,
	onStop: ((server: UdpServer) -> ())?,
	sendingThread: thread?,
	waitingSends: { thread },
}

return UdpServer.Interface
