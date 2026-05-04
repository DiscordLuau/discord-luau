local stdPolyfills = require("../luau_packages/std_polyfills")
local future = require("../luau_packages/future")
local logger = require("../luau_packages/logger")
local util = require("../luau_packages/util")

local rtp = require("./rtp")

local UDP_KEEPALIVE_INTERVAL = 5
local UDP_KEEPALIVE_TYPE = 0xC9
local UDP_KEEPALIVE_SIZE = 5

local RTP_VERSION_FLAGS = 0x80
local RTP_PAYLOAD_TYPE_OPUS = 0x78
local RTP_HEADER_SIZE = 12
local RTP_TIMESTAMP_INCREMENT = 960

--[=[
	@class Voice.UdpTransport
	@__index Prototype

	Manages the UDP socket for a voice connection: IP discovery, keepalive, RTP receive, and audio send.

	`decryptPacket` and `onAudioPacket` must be set by the owner before starting the receive loop.
]=]

--[=[
	@prop udpSocket stdPolyfills.UdpSocket?
	@within Voice.UdpTransport
]=]

--[=[
	@prop udpReceiveThread thread?
	@within Voice.UdpTransport
]=]

--[=[
	@prop keepaliveThread thread?
	@within Voice.UdpTransport
]=]

--[=[
	@prop keepaliveSequence number
	@within Voice.UdpTransport
]=]

--[=[
	@prop keepaliveSentAt { [number]: number }
	@within Voice.UdpTransport
]=]

--[=[
	@prop udpPing number?
	@within Voice.UdpTransport
]=]

--[=[
	@prop ssrc number?
	@within Voice.UdpTransport
]=]

--[=[
	@prop udpIp string?
	@within Voice.UdpTransport
]=]

--[=[
	@prop udpPort number?
	@within Voice.UdpTransport
]=]

--[=[
	@prop modes { string }?
	@within Voice.UdpTransport
]=]

--[=[
	@prop streams { { [string]: any } }?
	@within Voice.UdpTransport
]=]

--[=[
	@prop experiments { string }?
	@within Voice.UdpTransport
]=]

--[=[
	@prop decryptPacket ((packet: buffer) -> buffer?)?
	@within Voice.UdpTransport
]=]

--[=[
	@prop onAudioPacket ((ssrc: number, sequence: number, frame: buffer) -> ())?
	@within Voice.UdpTransport
]=]

--[=[
	@prop logger logger.Logger
	@within Voice.UdpTransport
]=]

local UdpTransport = {}

UdpTransport.Interface = {}
UdpTransport.Prototype = {}

--[=[
	@within Voice.UdpTransport

	Closes the UDP socket and stops both the receive loop and keepalive loop.
]=]
function UdpTransport.Prototype.cleanup(self: UdpTransport)
	if self.udpReceiveThread then
		coroutine.close(self.udpReceiveThread)
		self.udpReceiveThread = nil
	end

	if self.keepaliveThread then
		coroutine.close(self.keepaliveThread)
		self.keepaliveThread = nil
	end

	if self.udpSocket then
		pcall(self.udpSocket.close)
		self.udpSocket = nil
	end

	self.ssrc = nil
	self.udpIp = nil
	self.udpPort = nil
	self.udpPing = nil
	self.keepaliveSentAt = {}
	self.keepaliveSequence = 0
end

--[=[
	@within Voice.UdpTransport

	Performs UDP IP discovery via the voice server and returns the bot's external IP and port.
]=]
function UdpTransport.Prototype.discoverIpAsync(self: UdpTransport)
	return future.Future.new(function(): (string, number)
		assert(self.ssrc and self.udpIp and self.udpPort, `voice Ready payload has not been received yet.`)

		self.logger:info(`performing UDP IP discovery via {self.udpIp}:{self.udpPort}`)

		local request = buffer.create(74)
		local ssrc = self.ssrc :: number

		buffer.writeu8(request, 0, 0x00)
		buffer.writeu8(request, 1, 0x01)
		buffer.writeu8(request, 2, 0x00)
		buffer.writeu8(request, 3, 70)

		buffer.writeu8(request, 4, bit32.rshift(bit32.band(ssrc, 0xFF000000), 24))
		buffer.writeu8(request, 5, bit32.rshift(bit32.band(ssrc, 0x00FF0000), 16))
		buffer.writeu8(request, 6, bit32.rshift(bit32.band(ssrc, 0x0000FF00), 8))
		buffer.writeu8(request, 7, bit32.band(ssrc, 0x000000FF))

		self.udpSocket = stdPolyfills.net.udpSocket(self.udpIp :: string, self.udpPort :: number)

		if not self.udpSocket then
			return nil :: any, nil :: any
		end

		self.udpSocket.send(request)

		local response = self.udpSocket.next()

		assert(response and #response >= 74, `UDP IP discovery: invalid or missing response from voice server`)

		local responseBuf = buffer.fromstring(response :: string)
		local ipBytes = {}

		for offset = 8, 71 do
			local byte = buffer.readu8(responseBuf, offset)

			if byte == 0 then
				break
			end

			table.insert(ipBytes, string.char(byte))
		end

		local externalIp = table.concat(ipBytes)
		local externalPort = bit32.bor(bit32.lshift(buffer.readu8(responseBuf, 72), 8), buffer.readu8(responseBuf, 73))

		self.logger:info(`UDP IP discovery complete: {externalIp}:{externalPort}`)

		return externalIp, externalPort
	end) :: future.FutureLike<string, (string, number)>
end

--[=[
	@within Voice.UdpTransport

	Sends a single UDP keepalive packet and records the send time for RTT measurement.
]=]
function UdpTransport.Prototype._sendKeepalive(self: UdpTransport)
	local udpSocket = self.udpSocket

	if not udpSocket then
		return
	end

	local sequence = self.keepaliveSequence
	local keepalivePacket = buffer.create(UDP_KEEPALIVE_SIZE)

	buffer.writeu8(keepalivePacket, 0, UDP_KEEPALIVE_TYPE)
	buffer.writeu8(keepalivePacket, 1, bit32.rshift(bit32.band(sequence, 0xFF000000), 24))
	buffer.writeu8(keepalivePacket, 2, bit32.rshift(bit32.band(sequence, 0x00FF0000), 16))
	buffer.writeu8(keepalivePacket, 3, bit32.rshift(bit32.band(sequence, 0x0000FF00), 8))
	buffer.writeu8(keepalivePacket, 4, bit32.band(sequence, 0xFF))

	self.keepaliveSentAt[sequence] = os.clock()
	self.keepaliveSequence = sequence + 1

	pcall(udpSocket.send, keepalivePacket)
end

--[=[
	@within Voice.UdpTransport

	Starts the keepalive loop that fires every five seconds while the UDP socket is open.
]=]
function UdpTransport.Prototype._startKeepaliveLoop(self: UdpTransport)
	if self.keepaliveThread then
		return
	end

	self.keepaliveThread = util.coroutineRun(function()
		while self.udpSocket do
			self:_sendKeepalive()
			stdPolyfills.task.wait(UDP_KEEPALIVE_INTERVAL)
		end

		self.keepaliveThread = nil
	end)
end

--[=[
	@within Voice.UdpTransport

	Starts the UDP receive loop. Routes keepalive echo packets to the RTT tracker and RTP audio
	packets to `onAudioPacket` after decryption via `decryptPacket`.
]=]
function UdpTransport.Prototype._startUdpReceiveLoop(self: UdpTransport)
	if self.udpReceiveThread then
		return
	end

	self.udpReceiveThread = util.coroutineRun(function()
		while self.udpSocket do
			local udpSocket = self.udpSocket

			if not udpSocket then
				break
			end

			local success, rawPacket = pcall(udpSocket.next)

			if not success or not rawPacket then
				break
			end

			local packetBuffer = buffer.fromstring(rawPacket :: string)
			local firstByte = buffer.readu8(packetBuffer, 0)

			if firstByte == UDP_KEEPALIVE_TYPE and buffer.len(packetBuffer) == UDP_KEEPALIVE_SIZE then
				local echoedSequence = bit32.bor(
					bit32.lshift(buffer.readu8(packetBuffer, 1), 24),
					bit32.lshift(buffer.readu8(packetBuffer, 2), 16),
					bit32.lshift(buffer.readu8(packetBuffer, 3), 8),
					buffer.readu8(packetBuffer, 4)
				)

				local sentAt = self.keepaliveSentAt[echoedSequence]

				if sentAt then
					self.udpPing = os.clock() - sentAt
					self.keepaliveSentAt[echoedSequence] = nil
				end

				continue
			end

			if bit32.rshift(firstByte, 6) ~= 2 then
				continue
			end

			-- Skip RTCP packets (PT 200-207 = 0xC8-0xCF).
			local rawPayloadType = buffer.readu8(packetBuffer, 1)

			if rawPayloadType >= 200 and rawPayloadType <= 207 then
				continue
			end

			local decryptPacket = self.decryptPacket

			if not decryptPacket then
				continue
			end

			local decryptSuccess, decryptedPacket = pcall(decryptPacket, packetBuffer)

			if not decryptSuccess or not decryptedPacket then
				self.logger:warn(`RTP decrypt failed (packet={buffer.len(packetBuffer)}B): {decryptedPacket}`)
				continue
			end

			local sequence =
				bit32.bor(bit32.lshift(buffer.readu8(decryptedPacket, 2), 8), buffer.readu8(decryptedPacket, 3))

			local senderSsrc = bit32.bor(
				bit32.lshift(buffer.readu8(decryptedPacket, 8), 24),
				bit32.lshift(buffer.readu8(decryptedPacket, 9), 16),
				bit32.lshift(buffer.readu8(decryptedPacket, 10), 8),
				buffer.readu8(decryptedPacket, 11)
			)

			local frameLength = buffer.len(decryptedPacket) - RTP_HEADER_SIZE

			if frameLength <= 0 then
				continue
			end

			local audioFrame = buffer.create(frameLength)

			buffer.copy(audioFrame, 0, decryptedPacket, RTP_HEADER_SIZE, frameLength)

			if self.onAudioPacket then
				self.onAudioPacket(senderSsrc, sequence, audioFrame)
			end
		end

		self.udpReceiveThread = nil
	end)
end

--[=[
	@within Voice.UdpTransport

	Builds an RTP packet from the given Opus frame, encrypts it (with optional DAVE layer), and sends it over UDP.
]=]
function UdpTransport.Prototype.sendOpusAsync(
	self: UdpTransport,
	audioFrame: buffer,
	rtpCrypto: rtp.RtpCrypto,
	daveEncryptor: any?
)
	return future.Future.new(function()
		assert(self.udpSocket, "cannot send audio: UDP socket is not open")
		assert(self.ssrc, "cannot send audio: SSRC not assigned")
		assert(rtpCrypto.secretKey, "cannot send audio: no secret key")

		local currentSequence = rtpCrypto.rtpSequence
		local currentTimestamp = rtpCrypto.rtpTimestamp
		local ssrc = self.ssrc :: number
		local frameLength = buffer.len(audioFrame)

		local rtpPacket = buffer.create(RTP_HEADER_SIZE + frameLength)

		buffer.writeu8(rtpPacket, 0, RTP_VERSION_FLAGS)
		buffer.writeu8(rtpPacket, 1, RTP_PAYLOAD_TYPE_OPUS)

		buffer.writeu8(rtpPacket, 2, bit32.rshift(bit32.band(currentSequence, 0xFF00), 8))
		buffer.writeu8(rtpPacket, 3, bit32.band(currentSequence, 0xFF))

		buffer.writeu8(rtpPacket, 4, bit32.rshift(bit32.band(currentTimestamp, 0xFF000000), 24))
		buffer.writeu8(rtpPacket, 5, bit32.rshift(bit32.band(currentTimestamp, 0x00FF0000), 16))
		buffer.writeu8(rtpPacket, 6, bit32.rshift(bit32.band(currentTimestamp, 0x0000FF00), 8))
		buffer.writeu8(rtpPacket, 7, bit32.band(currentTimestamp, 0xFF))

		buffer.writeu8(rtpPacket, 8, bit32.rshift(bit32.band(ssrc, 0xFF000000), 24))
		buffer.writeu8(rtpPacket, 9, bit32.rshift(bit32.band(ssrc, 0x00FF0000), 16))
		buffer.writeu8(rtpPacket, 10, bit32.rshift(bit32.band(ssrc, 0x0000FF00), 8))
		buffer.writeu8(rtpPacket, 11, bit32.band(ssrc, 0xFF))

		buffer.copy(rtpPacket, RTP_HEADER_SIZE, audioFrame, 0, frameLength)

		local encryptedPacket = rtpCrypto:encryptRtp(rtpPacket, daveEncryptor, ssrc)

		xpcall(self.udpSocket.send, function(exception)
			self.logger:warn(`audio send failed: {exception}`)
		end, encryptedPacket)

		rtpCrypto.rtpSequence = bit32.band(currentSequence + 1, 0xFFFF)
		rtpCrypto.rtpTimestamp = bit32.band(currentTimestamp + RTP_TIMESTAMP_INCREMENT, 0xFFFFFFFF)
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Voice.UdpTransport

	Responsible for constructing this class.
]=]
function UdpTransport.Interface.new(loggerInstance: logger.Logger): UdpTransport
	return setmetatable(
		{
			keepaliveSequence = 0,
			keepaliveSentAt = {},
			logger = loggerInstance,
		} :: UdpTransport,
		{ __index = UdpTransport.Prototype }
	)
end

export type UdpTransport = typeof(UdpTransport.Prototype) & {
	udpSocket: stdPolyfills.UdpSocket?,
	udpReceiveThread: thread?,
	keepaliveThread: thread?,
	keepaliveSequence: number,
	keepaliveSentAt: { [number]: number },
	udpPing: number?,
	ssrc: number?,
	udpIp: string?,
	udpPort: number?,
	modes: { string }?,
	streams: { { [string]: any } }?,
	experiments: { string }?,
	decryptPacket: ((packet: buffer) -> buffer?)?,
	onAudioPacket: ((ssrc: number, sequence: number, frame: buffer) -> ())?,
	logger: logger.Logger,
}

return UdpTransport.Interface
