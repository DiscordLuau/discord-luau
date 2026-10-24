local stdPolyfills = require("../luau_packages/std_polyfills")
local future = require("../luau_packages/future")
local logger = require("../luau_packages/logger")

local voiceDaveManager = require("./dave")
local opusPacket = require("./opusPacket")
local rtp = require("./rtp")

local UDP_KEEPALIVE_INTERVAL = 5
local UDP_KEEPALIVE_TYPE = 0xC9
local UDP_KEEPALIVE_SIZE = 5

local RTP_VERSION_FLAGS = 0x80
local RTP_PAYLOAD_TYPE_OPUS = 0x78
local RTP_HEADER_SIZE = 12

local DISCOVERY_PACKET_SIZE = 74
local DISCOVERY_MESSAGE_LENGTH = 70
local DISCOVERY_REQUEST_TYPE = 0x0001
local DISCOVERY_RESPONSE_TYPE = 0x0002
local DISCOVERY_SSRC_OFFSET = 4
local DISCOVERY_ADDRESS_OFFSET = 8
local DISCOVERY_ADDRESS_SIZE = 64
local DISCOVERY_PORT_OFFSET = 72
local DISCOVERY_ATTEMPTS = 3
local DISCOVERY_TIMEOUT_SECONDS = 2
local DISCOVERY_POLL_SECONDS = 0.05

local MAX_CONSECUTIVE_RECEIVE_ERRORS = 10
local DECRYPT_WARNING_INTERVAL_SECONDS = 1

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
	@prop unreportedDecryptFailures number
	@within Voice.UdpTransport
]=]

--[=[
	@prop lastDecryptWarningClock number
	@within Voice.UdpTransport
]=]

--[=[
	@prop pendingSends { [stdPolyfills.UdpSocket]: number? }
	@within Voice.UdpTransport
	@private

	How many sends each socket has in flight; a socket is closed only once it has none.
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
	@prop substitutingSilence boolean
	@within Voice.UdpTransport
	@private

	Whether the latest audio send went out as DAVE silence, so each gap is logged once.
]=]

--[=[
	@prop decryptPacket ((packet: buffer) -> (buffer?, string?))?
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

local function readBigEndian16(packet: buffer, offset: number): number
	return bit32.bor(bit32.lshift(buffer.readu8(packet, offset), 8), buffer.readu8(packet, offset + 1))
end

local function writeBigEndian16(packet: buffer, offset: number, value: number)
	buffer.writeu8(packet, offset, bit32.rshift(value, 8))
	buffer.writeu8(packet, offset + 1, bit32.band(value, 0xFF))
end

local function discoveryRequest(ssrc: number): buffer
	local request = buffer.create(DISCOVERY_PACKET_SIZE)

	writeBigEndian16(request, 0, DISCOVERY_REQUEST_TYPE)
	writeBigEndian16(request, 2, DISCOVERY_MESSAGE_LENGTH)
	buffer.writeu32(request, DISCOVERY_SSRC_OFFSET, bit32.byteswap(ssrc))

	return request
end

local function parseDiscoveryReply(response: string, ssrc: number): DiscoveryReply?
	local packet = buffer.fromstring(response)
	local isReply = buffer.len(packet) == DISCOVERY_PACKET_SIZE
		and readBigEndian16(packet, 0) == DISCOVERY_RESPONSE_TYPE
		and readBigEndian16(packet, 2) == DISCOVERY_MESSAGE_LENGTH
		and bit32.byteswap(buffer.readu32(packet, DISCOVERY_SSRC_OFFSET)) == ssrc
	local addressLength = 0

	if not isReply then
		return
	end

	while
		addressLength < DISCOVERY_ADDRESS_SIZE
		and buffer.readu8(packet, DISCOVERY_ADDRESS_OFFSET + addressLength) ~= 0
	do
		addressLength += 1
	end

	return {
		address = buffer.readstring(packet, DISCOVERY_ADDRESS_OFFSET, addressLength),
		port = readBigEndian16(packet, DISCOVERY_PORT_OFFSET),
	}
end

--[=[
	@within Voice.UdpTransport

	Closes the UDP socket and stops both the receive loop and keepalive loop, without yielding. Neither thread is
	closed, since either can be parked in a socket operation: closing the socket wakes the receive loop's pending read
	with "Canceled", and both loops end at their next check because the socket is no longer this transport's.
]=]
function UdpTransport.Prototype.cleanup(self: UdpTransport)
	local udpSocket = self.udpSocket

	self.udpReceiveThread = nil
	self.keepaliveThread = nil
	self.udpSocket = nil

	if udpSocket then
		self:closeSocket(udpSocket)
	end

	self.ssrc = nil
	self.udpIp = nil
	self.udpPort = nil
	self.keepaliveSequence = 0
	self.substitutingSilence = false
end

--[=[
	@within Voice.UdpTransport

	Performs UDP IP discovery via the voice server and returns the bot's external IP and port. A reader thread waits
	for a reply that is 74 bytes, of type 0x0002 and for this ssrc; each request waits up to two seconds for it, three
	requests in all. Fails, closing the socket, when none is answered or the socket cannot be opened.
]=]
function UdpTransport.Prototype.discoverIpAsync(self: UdpTransport)
	return future.Future.new(function(): (string, number)
		local ssrc = self.ssrc
		local udpIp = self.udpIp
		local udpPort = self.udpPort

		assert(ssrc and udpIp and udpPort, `voice Ready payload has not been received yet.`)

		local opened, udpSocket = pcall(stdPolyfills.net.udpSocket, udpIp, udpPort)
		local request = discoveryRequest(ssrc)
		local reply: DiscoveryReply? = nil

		assert(opened and udpSocket, `UDP IP discovery could not open a socket to {udpIp}:{udpPort}: {udpSocket}`)

		self.udpSocket = udpSocket
		self.logger:info(`performing UDP IP discovery via {udpIp}:{udpPort}`)
		self:resumeThread(
			coroutine.create(function()
				while not reply do
					local received, response = pcall(udpSocket.next)

					if not received and self.udpSocket == udpSocket then
						self.logger:warn(`UDP discovery reader stopped: {response}`)

						return
					end

					if not received or not response then
						self.logger:debug(
							`UDP discovery reader stopped: {if received then "the socket closed" else response}`
						)

						return
					end

					reply = parseDiscoveryReply(response, ssrc)

					if not reply then
						self.logger:debug(
							`ignoring a {#response}-byte UDP packet that is not this ssrc's discovery reply`
						)
					end
				end
			end),
			"discovery reader"
		)

		for attempt = 1, DISCOVERY_ATTEMPTS do
			if self.udpSocket ~= udpSocket then
				self.logger:debug(`UDP discovery stopped: a newer voice session replaced its socket`)

				error(`UDP IP discovery was superseded by a newer voice session`, 0)
			end

			local sent, sendError = self:send(udpSocket, request)

			if not sent then
				self.logger:warn(`UDP discovery request failed to send: {sendError}`)
			end

			for _ = 1, DISCOVERY_TIMEOUT_SECONDS / DISCOVERY_POLL_SECONDS do
				if reply then
					break
				end

				stdPolyfills.task.wait(DISCOVERY_POLL_SECONDS)
			end

			if reply then
				break
			end

			self.logger:debug(
				`no UDP discovery reply within {DISCOVERY_TIMEOUT_SECONDS}s ({attempt}/{DISCOVERY_ATTEMPTS})`
			)
		end

		if not reply then
			local closed, closeError = pcall(udpSocket.close :: () -> ...any)

			if not closed then
				self.logger:debug(`UDP socket close errored after a failed discovery: {closeError}`)
			end

			if self.udpSocket == udpSocket then
				self.udpSocket = nil
			end

			error(`UDP IP discovery got no reply from {udpIp}:{udpPort} after {DISCOVERY_ATTEMPTS} attempts`, 0)
		end

		self.logger:info(`UDP IP discovery complete: {reply.address}:{reply.port}`)

		return reply.address, reply.port
	end) :: future.FutureLike<string, (string, number)>
end

--[=[
	@within Voice.UdpTransport

	Sends a single UDP keepalive packet, which keeps the NAT mapping for the voice socket open.
]=]
function UdpTransport.Prototype.sendKeepalive(self: UdpTransport)
	local udpSocket = self.udpSocket

	if not udpSocket then
		self.logger:debug(`no UDP socket, skipping the keepalive`)

		return
	end

	local sequence = self.keepaliveSequence
	local keepalivePacket = buffer.create(UDP_KEEPALIVE_SIZE)

	buffer.writeu8(keepalivePacket, 0, UDP_KEEPALIVE_TYPE)
	buffer.writeu8(keepalivePacket, 1, bit32.rshift(bit32.band(sequence, 0xFF000000), 24))
	buffer.writeu8(keepalivePacket, 2, bit32.rshift(bit32.band(sequence, 0x00FF0000), 16))
	buffer.writeu8(keepalivePacket, 3, bit32.rshift(bit32.band(sequence, 0x0000FF00), 8))
	buffer.writeu8(keepalivePacket, 4, bit32.band(sequence, 0xFF))

	local sent, sendError = self:send(udpSocket, keepalivePacket)

	self.keepaliveSequence = sequence + 1

	if not sent then
		self.logger:warn(`UDP keepalive failed to send: {sendError}`)
	end
end

--[=[
	@within Voice.UdpTransport

	Starts the keepalive loop that fires every five seconds while the UDP socket is open.
]=]
function UdpTransport.Prototype.startKeepaliveLoop(self: UdpTransport)
	local thread = coroutine.create(function()
		local myThread = coroutine.running()

		while self.udpSocket and self.keepaliveThread == myThread do
			self:sendKeepalive()
			stdPolyfills.task.wait(UDP_KEEPALIVE_INTERVAL)
		end

		if self.keepaliveThread == myThread then
			self.keepaliveThread = nil
		end
	end)

	if self.keepaliveThread then
		self.logger:debug(`UDP keepalive loop already running`)

		return
	end

	self.keepaliveThread = thread

	self:resumeThread(thread, "keepalive")
end

--[=[
	@within Voice.UdpTransport
	@private

	Handles one received datagram: drops anything that is not an RTP packet carrying Opus (payload type 0x78, marker
	bit ignored), so RTCP and other payload types never reach the decryptor, decrypts the rest and hands the frame to
	`onAudioPacket`.
]=]
function UdpTransport.Prototype.handlePacket(self: UdpTransport, rawPacket: string)
	local packetBuffer = buffer.fromstring(rawPacket)
	local packetLength = buffer.len(packetBuffer)

	print(`[trace {string.format("%.3f", os.clock())}] voice handlePacket {packetLength}B`)
	local firstByte = if packetLength > 0 then buffer.readu8(packetBuffer, 0) else 0

	if packetLength < RTP_HEADER_SIZE or bit32.rshift(firstByte, 6) ~= 2 then
		self.logger:debug(`skipping a {packetLength}B UDP packet that is not RTP`)

		return
	end

	local payloadType = bit32.band(buffer.readu8(packetBuffer, 1), 0x7F)

	if payloadType ~= RTP_PAYLOAD_TYPE_OPUS then
		self.logger:debug(`skipping an RTP packet with payload type {payloadType}, which is not Opus`)

		return
	end

	local decryptPacket = self.decryptPacket

	if not decryptPacket then
		self.logger:debug(`skipping an RTP packet: no decryptPacket handler is set`)

		return
	end

	local decryptSuccess, decryptedPacket, dropReason = pcall(decryptPacket, packetBuffer)

	if not decryptSuccess then
		local now = os.clock()

		self.unreportedDecryptFailures += 1

		if now - self.lastDecryptWarningClock >= DECRYPT_WARNING_INTERVAL_SECONDS then
			self.logger:warn(
				`RTP decrypt failed for {self.unreportedDecryptFailures} packet(s), latest {packetLength}B: {decryptedPacket}`
			)

			self.unreportedDecryptFailures = 0
			self.lastDecryptWarningClock = now
		end

		return
	end

	if not decryptedPacket then
		self.logger:debug(`dropping an RTP packet: {dropReason or "the decrypt handler returned nothing"}`)

		return
	end

	local sequence = bit32.bor(bit32.lshift(buffer.readu8(decryptedPacket, 2), 8), buffer.readu8(decryptedPacket, 3))
	local senderSsrc = bit32.bor(
		bit32.lshift(buffer.readu8(decryptedPacket, 8), 24),
		bit32.lshift(buffer.readu8(decryptedPacket, 9), 16),
		bit32.lshift(buffer.readu8(decryptedPacket, 10), 8),
		buffer.readu8(decryptedPacket, 11)
	)
	local frameLength = buffer.len(decryptedPacket) - RTP_HEADER_SIZE

	if frameLength <= 0 then
		self.logger:debug(`skipping an RTP packet with an empty payload`)

		return
	end

	local audioFrame = buffer.create(frameLength)

	buffer.copy(audioFrame, 0, decryptedPacket, RTP_HEADER_SIZE, frameLength)

	print(`[trace {string.format("%.3f", os.clock())}] voice delivering seq {sequence}`)

	if self.onAudioPacket then
		local delivered, deliveryError =
			xpcall(self.onAudioPacket :: any, debug.traceback, senderSsrc, sequence, audioFrame)

		if not delivered then
			self.logger:warn(`UDP audio packet handler errored:\n{deliveryError}`)
		end
	end
end

--[=[
	@within Voice.UdpTransport

	Starts the UDP receive loop. Routes RTP audio packets to `onAudioPacket` after decryption via `decryptPacket`;
	anything else is skipped with a debug line.
]=]
function UdpTransport.Prototype.startUdpReceiveLoop(self: UdpTransport)
	local thread = coroutine.create(function()
		local myThread = coroutine.running()
		local consecutiveErrors = 0

		self.unreportedDecryptFailures = 0
		self.lastDecryptWarningClock = -math.huge

		while self.udpSocket and self.udpReceiveThread == myThread do
			local udpSocket = self.udpSocket :: stdPolyfills.UdpSocket
			local success, rawPacket = pcall(udpSocket.next)

			if self.udpSocket ~= udpSocket or self.udpReceiveThread ~= myThread then
				break
			end

			if not success or not rawPacket then
				consecutiveErrors += 1

				self.logger:warn(`UDP receive failed ({consecutiveErrors} in a row): {rawPacket or "socket closed"}`)

				if consecutiveErrors >= MAX_CONSECUTIVE_RECEIVE_ERRORS then
					self.logger:warn(`UDP receive loop stopped after {consecutiveErrors} consecutive failures`)

					break
				end

				continue
			end

			local handled, handleError = xpcall(
				self.handlePacket :: (UdpTransport, string) -> ...any,
				debug.traceback,
				self,
				rawPacket :: string
			)

			if not handled then
				self.logger:warn(`UDP packet handling errored:\n{handleError}`)
			end

			consecutiveErrors = 0
		end

		if self.udpReceiveThread == myThread then
			self.udpReceiveThread = nil
		end
	end)

	if self.udpReceiveThread then
		self.logger:debug(`UDP receive loop already running`)

		return
	end

	self.udpReceiveThread = thread

	self:resumeThread(thread, "receive loop")
end

--[=[
	@within Voice.UdpTransport
	@private

	Resumes a thread this transport owns, logging at warn with a traceback if it errors before its first yield.
]=]
function UdpTransport.Prototype.resumeThread(self: UdpTransport, thread: thread, purpose: string)
	local resumed, resumeError = coroutine.resume(thread)

	if not resumed then
		self.logger:warn(`UDP {purpose} thread errored:\n{debug.traceback(thread, tostring(resumeError))}`)
	end
end

--[=[
	@within Voice.UdpTransport
	@private

	Closes a UDP socket on its own thread, because Zune's close yields and `cleanup` must not. It waits for the
	socket's sends in flight first: Zune prints "Cancel Error: error.NotFound" when a socket closes under one.
]=]
function UdpTransport.Prototype.closeSocket(self: UdpTransport, udpSocket: stdPolyfills.UdpSocket)
	self:resumeThread(
		coroutine.create(function()
			while self.pendingSends[udpSocket] do
				stdPolyfills.task.wait()
			end

			local closed, closeError = pcall(udpSocket.close :: () -> ...any)

			if not closed then
				self.logger:debug(`UDP socket close errored, assuming closed: {closeError}`)
			end
		end),
		"socket close"
	)
end

--[=[
	@within Voice.UdpTransport
	@private

	Sends one packet on `udpSocket`, counting it in `pendingSends` until Zune finishes it. Returns pcall's result.
]=]
function UdpTransport.Prototype.send(
	self: UdpTransport,
	udpSocket: stdPolyfills.UdpSocket,
	packet: buffer
): (boolean, any)
	self.pendingSends[udpSocket] = (self.pendingSends[udpSocket] or 0) + 1

	local sent, sendError = pcall(udpSocket.send :: (buffer) -> ...any, packet)
	local remaining = (self.pendingSends[udpSocket] :: number) - 1

	self.pendingSends[udpSocket] = if remaining > 0 then remaining else nil

	return sent, sendError
end

--[=[
	@within Voice.UdpTransport

	Builds an RTP packet from the given Opus frame, encrypts it and sends it over UDP. The RTP timestamp advances by
	the samples the frame's TOC byte describes (`opusSamples`), and an invalid frame fails before a sequence number or
	timestamp is reserved. `daveManager`'s encryptor, `mediaProtocolVersion` and `mediaReady` are read when the future
	runs, not when it is created, so a send that waits through a DAVE group reset never touches the destroyed
	encryptor. Fails while `mediaProtocolVersion` is unknown, because the frame could otherwise leave without DAVE in a
	DAVE channel. Under DAVE until media is ready, Opus silence goes out in place of the frame, logged at debug once per
	gap, and the timestamp still advances by the frame's samples; the gap is marked before the send yields, so a send
	still in flight when `cleanup` runs cannot carry its gap into the next session. Fails with `audio send failed:
	<reason>` when the socket send fails; the sequence number and timestamp stay used, so the receiver sees plain loss.
]=]
function UdpTransport.Prototype.sendOpusAsync(
	self: UdpTransport,
	audioFrame: buffer,
	rtpCrypto: rtp.RtpCrypto,
	daveManager: voiceDaveManager.DaveManager
)
	return future.Future.new(function()
		local udpSocket = self.udpSocket
		local ssrc = self.ssrc
		local daveEncryptor = daveManager.daveEncryptor
		local mediaProtocolVersion = daveManager.mediaProtocolVersion
		local mediaReady = daveManager.mediaReady
		local currentSequence = rtpCrypto.rtpSequence
		local currentTimestamp = rtpCrypto.rtpTimestamp
		local samples = opusPacket.opusSamples(audioFrame)
		local frameLength = buffer.len(audioFrame)
		local rtpPacket = buffer.create(RTP_HEADER_SIZE + frameLength)

		assert(udpSocket, "cannot send audio: UDP socket is not open")
		assert(ssrc, "cannot send audio: SSRC not assigned")
		assert(rtpCrypto.secretKey, "cannot send audio: no secret key")
		assert(mediaProtocolVersion, "cannot send audio: the DAVE protocol version is not known yet")

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

		rtpCrypto.rtpSequence = bit32.band(currentSequence + 1, 0xFFFF)
		rtpCrypto.rtpTimestamp = bit32.band(currentTimestamp + samples, 0xFFFFFFFF)

		local encryptedPacket, substitutedSilence =
			rtpCrypto:encryptRtp(rtpPacket, daveEncryptor, ssrc, mediaProtocolVersion, mediaReady)

		if substitutedSilence and not self.substitutingSilence then
			self.logger:debug(`sending Opus silence in place of audio until DAVE media is ready`)
		end

		self.substitutingSilence = substitutedSilence

		local sent, sendError = self:send(udpSocket, encryptedPacket)

		assert(sent, `audio send failed: {sendError}`)
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
			unreportedDecryptFailures = 0,
			lastDecryptWarningClock = -math.huge,
			pendingSends = {},
			substitutingSilence = false,
			logger = loggerInstance,
		} :: UdpTransport,
		{ __index = UdpTransport.Prototype }
	)
end

type DiscoveryReply = { address: string, port: number }

export type UdpTransport = typeof(UdpTransport.Prototype) & {
	udpSocket: stdPolyfills.UdpSocket?,
	udpReceiveThread: thread?,
	keepaliveThread: thread?,
	keepaliveSequence: number,
	unreportedDecryptFailures: number,
	lastDecryptWarningClock: number,
	pendingSends: { [stdPolyfills.UdpSocket]: number? },
	substitutingSilence: boolean,
	ssrc: number?,
	udpIp: string?,
	udpPort: number?,
	modes: { string }?,
	streams: { { [string]: any } }?,
	experiments: { string }?,
	decryptPacket: ((packet: buffer) -> (buffer?, string?))?,
	onAudioPacket: ((ssrc: number, sequence: number, frame: buffer) -> ())?,
	logger: logger.Logger,
}

return UdpTransport.Interface
