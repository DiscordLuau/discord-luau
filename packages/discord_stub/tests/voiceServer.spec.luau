local frktest = require("../../../luau_packages/frktest")
local stdPolyfills = require("../luau_packages/std_polyfills")

local discordStub = require("../src/init")

local MODE = "aead_xchacha20_poly1305_rtpsize"

local test = frktest.test
local check = frktest.assert.check

local function connect(url: string, messages: { Message }, closed: { number }): HttpWebSocket
	return zune.net.http.websocket(url, {
		message = function(_, message)
			local decoded, payload = pcall(function()
				return stdPolyfills.serde.decode("json", message)
			end)

			table.insert(messages, { raw = message, payload = if decoded then payload else nil })
		end,
		close = function(_, code)
			table.insert(closed, code)
		end,
	})
end

local function sendPayload(socket: HttpWebSocket, payload: any)
	socket:send(stdPolyfills.serde.encode("json", payload))
end

local function findOp(messages: { Message }, opcode: number): any
	for _, message in messages do
		if message.payload and message.payload.op == opcode then
			return message.payload
		end
	end

	return
end

local function opcodesOf(messages: { Message }): { number }
	local opcodes = {}

	for _, message in messages do
		if message.payload then
			table.insert(opcodes, message.payload.op)
		end
	end

	return opcodes
end

local function identifyPayload(voice: discordStub.VoiceServer): any
	return {
		op = 0,
		d = {
			server_id = "10",
			user_id = "1",
			session_id = voice.sessionId,
			token = voice.token,
			max_dave_protocol_version = 0,
		},
	}
end

local function selectProtocolPayload(mode: string): any
	return { op = 1, d = { protocol = "udp", data = { address = "127.0.0.1", port = 50000, mode = mode } } }
end

local function openIdentified(stub: discordStub.DiscordStub, voice: discordStub.VoiceServer, messages: { Message })
	local socket = connect(voice.url, messages, {})

	assert(
		stub.clock:waitFor(function()
			return findOp(messages, 8)
		end, 30),
		"no Hello"
	)

	sendPayload(socket, identifyPayload(voice))

	assert(
		stub.clock:waitFor(function()
			return findOp(messages, 2)
		end, 30),
		"no Ready"
	)

	return socket
end

type Message = { raw: string | buffer, payload: any }

return function()
	test.suite("discord_stub voice server", function()
		test.case("the handshake runs Hello, Identify, Ready, Select Protocol, Session Description in order", function()
			local stub = discordStub.new({ clock = "virtual" })
			local voice = stub:createVoiceServer()
			local messages = {}
			local socket = connect(`{voice.url}/?v=8`, messages, {})
			local secretKey = {}

			for index = 0, buffer.len(voice.secretKey) - 1 do
				table.insert(secretKey, buffer.readu8(voice.secretKey, index))
			end

			check.is_true(stub.clock:waitFor(function()
				return findOp(messages, 8)
			end, 30))

			check.equal(findOp(messages, 8).d.heartbeat_interval, 41250)

			sendPayload(socket, identifyPayload(voice))

			check.is_true(stub.clock:waitFor(function()
				return findOp(messages, 2)
			end, 30))

			local ready = findOp(messages, 2)

			check.equal(ready.d.ssrc, 1234)
			check.equal(ready.d.ip, "127.0.0.1")
			check.equal(ready.d.port, voice.udpServer.port)
			check.array.equal(ready.d.modes, { "aead_aes256_gcm_rtpsize", MODE })
			check.equal(ready.d.heartbeat_interval, 41250)

			sendPayload(socket, selectProtocolPayload(MODE))

			check.is_true(stub.clock:waitFor(function()
				return findOp(messages, 4)
			end, 30))

			local description = findOp(messages, 4)

			check.equal(description.d.mode, MODE)
			check.equal(#secretKey, 32)
			check.array.equal(description.d.secret_key, secretKey)
			check.equal(description.d.dave_protocol_version, 0)
			check.array.equal(opcodesOf(messages), { 8, 2, 4 })
			check.array.equal(voice:receivedOps(), { 0, 1 })
			check.equal(voice.selectedMode, MODE)
			check.equal(voice.serverId, "10")
			check.equal(voice.connections[1].sessionId, voice.sessionId)
			check.equal(voice.connections[1].path, "/")

			stub:stop()
		end)

		test.case("Select Protocol with a mode Ready did not offer is closed with 4016", function()
			local stub = discordStub.new({ clock = "virtual" })
			local voice = stub:createVoiceServer({ modes = { MODE } })
			local messages = {}
			local closed = {}
			local socket = connect(voice.url, messages, closed)

			check.is_true(stub.clock:waitFor(function()
				return findOp(messages, 8)
			end, 30))

			sendPayload(socket, identifyPayload(voice))
			sendPayload(socket, selectProtocolPayload("aead_aes256_gcm_rtpsize"))

			check.is_true(stub.clock:waitFor(function()
				return closed[1] == 4016
			end, 30))

			check.equal(voice.connections[1].closeCode, 4016)
			check.equal(voice.selectedMode, nil)
			check.equal(findOp(messages, 4), nil)

			stub:stop()
		end)

		test.case("Heartbeat is answered with an ACK echoing t, and waitForOp waits on received opcodes", function()
			local stub = discordStub.new({ clock = "virtual" })
			local voice = stub:createVoiceServer()
			local messages = {}
			local socket = connect(voice.url, messages, {})

			check.is_true(stub.clock:waitFor(function()
				return findOp(messages, 8)
			end, 30))

			sendPayload(socket, { op = 3, d = { t = 1501184119561, seq_ack = 10 } })

			check.is_true(voice:waitForOp(3, 30))
			check.is_true(stub.clock:waitFor(function()
				return findOp(messages, 6)
			end, 30))

			check.equal(findOp(messages, 6).d.t, 1501184119561)
			check.equal((voice.received[1].payload.d :: any).seq_ack, 10)
			check.is_false(voice:waitForOp(7, 1))

			stub:stop()
		end)

		test.case("Resume with the identified server, session and token is answered with Resumed", function()
			local stub = discordStub.new({ clock = "virtual" })
			local voice = stub:createVoiceServer()
			local resumedMessages = {}

			openIdentified(stub, voice, {})

			local resumeSocket = connect(voice.url, resumedMessages, {})

			check.is_true(stub.clock:waitFor(function()
				return findOp(resumedMessages, 8)
			end, 30))

			sendPayload(resumeSocket, {
				op = 7,
				d = { server_id = "10", session_id = voice.sessionId, token = voice.token, seq_ack = 3 },
			})

			check.is_true(stub.clock:waitFor(function()
				return findOp(resumedMessages, 9)
			end, 30))

			local resumed = resumedMessages[#resumedMessages]

			check.truthy(string.match(resumed.raw :: string, '"d":null'))
			check.equal(voice.connections[2].sessionId, voice.sessionId)
			check.is_true(voice.connections[2].open)

			stub:stop()
		end)

		test.case("Resume before any Identify or with a wrong token is closed with 4006", function()
			local stub = discordStub.new({ clock = "virtual" })
			local voice = stub:createVoiceServer()
			local earlyMessages = {}
			local earlyClosed = {}
			local earlySocket = connect(voice.url, earlyMessages, earlyClosed)

			check.is_true(stub.clock:waitFor(function()
				return findOp(earlyMessages, 8)
			end, 30))

			sendPayload(earlySocket, {
				op = 7,
				d = { server_id = "10", session_id = voice.sessionId, token = voice.token, seq_ack = 0 },
			})

			check.is_true(stub.clock:waitFor(function()
				return earlyClosed[1] == 4006
			end, 30))

			openIdentified(stub, voice, {})

			local wrongMessages = {}
			local wrongClosed = {}
			local wrongSocket = connect(voice.url, wrongMessages, wrongClosed)

			check.is_true(stub.clock:waitFor(function()
				return findOp(wrongMessages, 8)
			end, 30))

			sendPayload(wrongSocket, {
				op = 7,
				d = { server_id = "10", session_id = voice.sessionId, token = "wrong-token", seq_ack = 0 },
			})

			check.is_true(stub.clock:waitFor(function()
				return wrongClosed[1] == 4006
			end, 30))

			check.equal(voice.connections[1].closeCode, 4006)
			check.equal(voice.connections[3].closeCode, 4006)
			check.equal(voice.connections[3].sessionId, nil)
			check.equal(findOp(wrongMessages, 9), nil)

			stub:stop()
		end)

		test.case(
			"binary messages carry a 2-byte big-endian sequence and the opcode before the payload, JSON ones carry seq",
			function()
				local stub = discordStub.new({ clock = "virtual" })
				local voice = stub:createVoiceServer()
				local messages = {}

				connect(voice.url, messages, {})

				check.is_true(stub.clock:waitFor(function()
					return findOp(messages, 8)
				end, 30))

				voice:sendJson(21, { transition_id = 1, protocol_version = 1 })
				voice:sendBinary(25, buffer.fromstring("pkg"))

				check.is_true(stub.clock:waitFor(function()
					return #messages == 3
				end, 30))

				local binaryFrame = messages[3].raw :: buffer

				check.equal(findOp(messages, 21).seq, 1)
				check.equal(findOp(messages, 21).d.transition_id, 1)
				check.equal(typeof(messages[3].raw), "buffer")
				check.equal(buffer.len(binaryFrame), 6)
				check.equal(buffer.readu8(binaryFrame, 0), 0)
				check.equal(buffer.readu8(binaryFrame, 1), 2)
				check.equal(buffer.readu8(binaryFrame, 2), 25)
				check.equal(buffer.readstring(binaryFrame, 3, 3), "pkg")

				voice.sequence = 0x01FF
				voice:sendBinary(29, buffer.create(0))

				check.is_true(stub.clock:waitFor(function()
					return #messages == 4
				end, 30))

				local wrappedFrame = messages[4].raw :: buffer

				check.equal(buffer.len(wrappedFrame), 3)
				check.equal(buffer.readu8(wrappedFrame, 0), 0x02)
				check.equal(buffer.readu8(wrappedFrame, 1), 0x00)
				check.equal(buffer.readu8(wrappedFrame, 2), 29)
				check.equal(voice.sequence, 0x0200)

				stub:stop()
			end
		)

		test.case("Speaking, Clients Connect and Client Disconnect carry their fields and a rising seq", function()
			local stub = discordStub.new({ clock = "virtual" })
			local voice = stub:createVoiceServer()
			local messages = {}

			connect(voice.url, messages, {})

			check.is_true(stub.clock:waitFor(function()
				return findOp(messages, 8)
			end, 30))

			voice:sendSpeaking("30", 5678, 1)
			voice:sendClientsConnect({ "30", "31" })
			voice:sendClientDisconnect("31")

			check.is_true(stub.clock:waitFor(function()
				return #messages == 4
			end, 30))

			local speaking = findOp(messages, 5)
			local clientsConnect = findOp(messages, 11)
			local clientDisconnect = findOp(messages, 13)

			check.array.equal(opcodesOf(messages), { 8, 5, 11, 13 })
			check.equal(speaking.d.user_id, "30")
			check.equal(speaking.d.ssrc, 5678)
			check.equal(speaking.d.speaking, 1)
			check.equal(speaking.seq, 1)
			check.array.equal(clientsConnect.d.user_ids, { "30", "31" })
			check.equal(clientsConnect.seq, 2)
			check.equal(clientDisconnect.d.user_id, "31")
			check.equal(clientDisconnect.seq, 3)

			stub:stop()
		end)

		test.case("every client message is recorded with its opcode, decoded payload and raw text or buffer", function()
			local stub = discordStub.new({ clock = "virtual" })
			local voice = stub:createVoiceServer()
			local messages = {}
			local socket = connect(voice.url, messages, {})
			local speakingText = '{"op":5,"d":{"speaking":1,"delay":0,"ssrc":1234}}'
			local keyPackage = buffer.create(4)

			buffer.writeu8(keyPackage, 0, 26)
			buffer.writestring(keyPackage, 1, "key")

			check.is_true(stub.clock:waitFor(function()
				return findOp(messages, 8)
			end, 30))

			socket:send(speakingText)
			socket:send(keyPackage)

			check.is_true(stub.clock:waitFor(function()
				return #voice.received == 2
			end, 30))

			local textRecord = voice.received[1]
			local binaryRecord = voice.received[2]

			check.equal(textRecord.opcode, 5)
			check.equal(textRecord.raw, speakingText)
			check.equal(textRecord.payload.d.ssrc, 1234)
			check.equal(binaryRecord.opcode, 26)
			check.equal(typeof(binaryRecord.raw), "buffer")
			check.equal(buffer.tostring(binaryRecord.raw :: buffer), "\26key")
			check.equal(buffer.tostring(binaryRecord.payload.d :: buffer), "key")
			check.equal(voice.connections[1].received[2], binaryRecord)
			check.lesser_eq(textRecord.at, binaryRecord.at)
			check.array.equal(voice:receivedOps(), { 5, 26 })

			stub:stop()
		end)

		test.case("a message that does not decode is closed with 4002 and is not recorded", function()
			local stub = discordStub.new({ clock = "virtual" })
			local voice = stub:createVoiceServer()
			local messages = {}
			local closed = {}
			local socket = connect(voice.url, messages, closed)

			check.is_true(stub.clock:waitFor(function()
				return findOp(messages, 8)
			end, 30))

			socket:send("{oops")

			check.is_true(stub.clock:waitFor(function()
				return closed[1] == 4002
			end, 30))

			check.equal(#voice.received, 0)
			check.equal(#voice.errors, 0)

			stub:stop()
		end)

		test.case("an error answering a message lands in errors and runScenario returns it", function()
			local stub = discordStub.new({ clock = "virtual" })
			local voice = stub:createVoiceServer()
			local result = stub:runScenario(function()
				local messages = {}
				local socket = connect(voice.url, messages, {})

				assert(
					stub.clock:waitFor(function()
						return findOp(messages, 8)
					end, 30),
					"no Hello"
				)

				sendPayload(socket, { op = 1, d = 5 })

				assert(
					stub.clock:waitFor(function()
						return #voice.errors == 1
					end, 30),
					"the voice error was not recorded"
				)
			end)

			check.equal(result, voice.errors[1])
			check.truthy(string.match(voice.errors[1], "attempt to index"))
			check.equal(stub.voiceServer, nil)
		end)

		test.case("close and stop close every open connection, and stop is safe twice", function()
			local stub = discordStub.new({ clock = "virtual" })
			local voice = stub:createVoiceServer()
			local firstMessages = {}
			local firstClosed = {}
			local secondMessages = {}
			local secondClosed = {}

			connect(voice.url, firstMessages, firstClosed)

			check.is_true(stub.clock:waitFor(function()
				return findOp(firstMessages, 8)
			end, 30))

			voice:close(4014)

			check.is_true(stub.clock:waitFor(function()
				return firstClosed[1] == 4014
			end, 30))

			connect(voice.url, secondMessages, secondClosed)

			check.is_true(stub.clock:waitFor(function()
				return findOp(secondMessages, 8)
			end, 30))

			voice:stop()

			check.is_true(stub.clock:waitFor(function()
				return secondClosed[1] == 1000
			end, 30))

			voice:stop()

			check.equal(voice.server, nil)
			check.equal(stub.voiceServer, nil)
			check.equal(#firstClosed, 1)

			stub:stop()
		end)

		test.case("with ackHeartbeats off, a Heartbeat gets no ACK", function()
			local stub = discordStub.new({ clock = "virtual" })
			local voice = stub:createVoiceServer()
			local messages = {}
			local socket = connect(voice.url, messages, {})

			voice.ackHeartbeats = false

			check.is_true(stub.clock:waitFor(function()
				return findOp(messages, 8)
			end, 30))

			sendPayload(socket, { op = 3, d = { t = 1, seq_ack = -1 } })

			check.is_true(voice:waitForOp(3, 30))
			check.is_false(stub.clock:waitFor(function()
				return findOp(messages, 6)
			end, 2))

			stub:stop()
		end)

		test.case("refuseUpgrades refuses that many connects, then accepts again", function()
			local stub = discordStub.new({ clock = "virtual" })
			local voice = stub:createVoiceServer()
			local messages = {}

			voice.refuseUpgrades = 1

			local refused, failure = pcall(connect, voice.url, {}, {})

			connect(voice.url, messages, {})

			check.is_false(refused)
			check.equal(failure, "UpgradeFailed")
			check.equal(voice.refuseUpgrades, 0)
			check.is_true(stub.clock:waitFor(function()
				return findOp(messages, 8)
			end, 30))
			check.equal(#voice.connections, 1)

			stub:stop()
		end)

		test.case("upgradeDelaySeconds holds the upgrade with handshaking set", function()
			local stub = discordStub.new({ clock = "virtual" })
			local voice = stub:createVoiceServer()
			local messages = {}

			voice.upgradeDelaySeconds = 5

			zune.task.spawn(function()
				connect(voice.url, messages, {})
			end)

			check.is_true(stub.clock:waitFor(function()
				return voice.handshaking
			end, 30))
			check.equal(#voice.connections, 0)
			check.is_true(stub.clock:waitFor(function()
				return findOp(messages, 8)
			end, 30))
			check.is_false(voice.handshaking)

			stub:stop()
		end)
	end)
end
