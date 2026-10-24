local frktest = require("../../../luau_packages/frktest")
local stdPolyfills = require("../luau_packages/std_polyfills")

local discordStub = require("../src/init")

local IDENTIFY_PAYLOAD = { op = 2, d = { token = "stub-token", intents = 0 } }

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

local function findEvent(messages: { Message }, eventName: string): Message?
	for _, message in messages do
		if message.payload and message.payload.t == eventName then
			return message
		end
	end

	return
end

local function eventNames(messages: { Message }): { string }
	local names = {}

	for _, message in messages do
		if message.payload and message.payload.t then
			table.insert(names, message.payload.t)
		end
	end

	return names
end

local function openIdentified(stub: discordStub.DiscordStub, url: string, messages: { Message }): HttpWebSocket
	local socket = connect(url, messages, {})

	assert(
		stub.clock:waitFor(function()
			return findOp(messages, 10)
		end, 30),
		"no Hello"
	)

	sendPayload(socket, IDENTIFY_PAYLOAD)

	assert(
		stub.clock:waitFor(function()
			return findEvent(messages, "READY")
		end, 30),
		"no READY"
	)

	return socket
end

type Message = { raw: string | buffer, payload: any }

return function()
	test.suite("discord_stub voice gateway hook", function()
		test.case(
			"joining a channel dispatches VOICE_STATE_UPDATE then VOICE_SERVER_UPDATE pointing at the voice server",
			function()
				local stub = discordStub.new({ clock = "virtual" })
				local ws = stub:createWebsocketServer()
				local voice = stub:createVoiceServer()
				local messages = {}
				local socket = openIdentified(stub, ws.url, messages)

				sendPayload(socket, {
					op = 4,
					d = { guild_id = "10", channel_id = "20", self_mute = true, self_deaf = false },
				})

				check.is_true(stub.clock:waitFor(function()
					return findEvent(messages, "VOICE_SERVER_UPDATE")
				end, 30))

				local ready = (findEvent(messages, "READY") :: Message).payload
				local state = (findEvent(messages, "VOICE_STATE_UPDATE") :: Message).payload
				local server = (findEvent(messages, "VOICE_SERVER_UPDATE") :: Message).payload

				check.array.equal(eventNames(messages), { "READY", "VOICE_STATE_UPDATE", "VOICE_SERVER_UPDATE" })
				check.equal(ws.voiceServer, voice)
				check.equal(state.d.guild_id, "10")
				check.equal(state.d.channel_id, "20")
				check.equal(state.d.user_id, ready.d.user.id)
				check.equal(state.d.session_id, voice.sessionId)
				check.is_false(state.d.deaf)
				check.is_false(state.d.mute)
				check.is_true(state.d.self_mute)
				check.is_false(state.d.self_deaf)
				check.equal(server.d.token, voice.token)
				check.equal(server.d.guild_id, "10")
				check.equal(server.d.endpoint, voice.url)
				check.lesser(state.s, server.s)

				stub:stop()
			end
		)

		test.case(
			"leaving dispatches a null channel_id, no VOICE_SERVER_UPDATE, and closes the voice socket with 4014",
			function()
				local stub = discordStub.new({ clock = "virtual" })
				local ws = stub:createWebsocketServer()
				local voice = stub:createVoiceServer()
				local messages = {}
				local voiceMessages = {}
				local voiceClosed = {}
				local socket = openIdentified(stub, ws.url, messages)
				local leaveText = '{"op":4,"d":{"guild_id":"10","channel_id":null,"self_mute":false,"self_deaf":false}}'

				connect(voice.url, voiceMessages, voiceClosed)

				check.is_true(stub.clock:waitFor(function()
					return findOp(voiceMessages, 8)
				end, 30))

				socket:send(leaveText)

				check.is_true(stub.clock:waitFor(function()
					return findEvent(messages, "VOICE_STATE_UPDATE") and voiceClosed[1] == 4014
				end, 30))

				local state = findEvent(messages, "VOICE_STATE_UPDATE") :: Message

				check.truthy(string.match(state.raw :: string, '"channel_id":null'))
				check.equal(state.payload.d.channel_id, nil)
				check.equal(state.payload.d.session_id, voice.sessionId)
				check.equal(findEvent(messages, "VOICE_SERVER_UPDATE"), nil)
				check.equal(voice.connections[1].closeCode, 4014)
				check.equal(ws:receivedOps(4)[1].raw, leaveText)

				stub:stop()
			end
		)

		test.case("moveVoice dispatches the update pair for the new channel", function()
			local stub = discordStub.new({ clock = "virtual" })
			local ws = stub:createWebsocketServer()
			local voice = stub:createVoiceServer()
			local messages = {}

			openIdentified(stub, ws.url, messages)
			ws:moveVoice("10", "30")

			check.is_true(stub.clock:waitFor(function()
				return findEvent(messages, "VOICE_SERVER_UPDATE")
			end, 30))

			local state = (findEvent(messages, "VOICE_STATE_UPDATE") :: Message).payload
			local server = (findEvent(messages, "VOICE_SERVER_UPDATE") :: Message).payload

			check.equal(state.d.guild_id, "10")
			check.equal(state.d.channel_id, "30")
			check.equal(server.d.endpoint, voice.url)
			check.equal(server.d.token, voice.token)

			stub:stop()
		end)

		test.case("a handler that answers op 4 replaces the voice default", function()
			local stub = discordStub.new({ clock = "virtual" })
			local handledWs = stub:createWebsocketServer(function(_, payload)
				return if payload.op == 4 then false else nil
			end)
			local handledMessages = {}
			local handledSocket = openIdentified(stub, handledWs.url, handledMessages)

			stub:createVoiceServer()
			sendPayload(handledSocket, { op = 4, d = { guild_id = "10", channel_id = "20" } })
			sendPayload(handledSocket, { op = 1 })

			check.is_true(stub.clock:waitFor(function()
				return findOp(handledMessages, 11)
			end, 30))

			check.equal(#handledWs:receivedOps(4), 1)
			check.array.equal(eventNames(handledMessages), { "READY" })

			stub:stop()
		end)

		test.case("without a voice server op 4 gets no reply and moveVoice errors", function()
			local bareStub = discordStub.new({ clock = "virtual" })
			local bareWs = bareStub:createWebsocketServer()
			local bareMessages = {}
			local bareSocket = openIdentified(bareStub, bareWs.url, bareMessages)

			sendPayload(bareSocket, { op = 4, d = { guild_id = "10", channel_id = "20" } })
			sendPayload(bareSocket, { op = 1 })

			check.is_true(bareStub.clock:waitFor(function()
				return findOp(bareMessages, 11)
			end, 30))

			check.equal(#bareWs:receivedOps(4), 1)
			check.array.equal(eventNames(bareMessages), { "READY" })

			local moved = pcall(function()
				bareWs:moveVoice("10", "30")
			end)

			check.is_false(moved)

			bareStub:stop()
		end)

		test.case(
			"createVoiceServer before the websocket server still attaches it, and stop tears both voice servers down",
			function()
				local stub = discordStub.new({ clock = "virtual" })
				local voice = stub:createVoiceServer({ token = "custom-token", sessionId = "custom-session" })
				local udp = voice.udpServer
				local ws = stub:createWebsocketServer()

				check.equal(ws.voiceServer, voice)
				check.equal(stub.voiceServer, voice)
				check.equal(stub.udpServer, udp)
				check.equal(voice.token, "custom-token")
				check.equal(voice.sessionId, "custom-session")

				local createdTwice = pcall(function()
					stub:createVoiceServer()
				end)

				check.is_false(createdTwice)

				stub:stop()

				check.is_true(stub.clock:waitFor(function()
					return not udp.receiving
				end, 30))

				check.equal(stub.voiceServer, nil)
				check.equal(stub.udpServer, nil)
				check.equal(voice.server, nil)
				check.equal(udp.socket, nil)
			end
		)

		test.case("disconnectVoice dispatches a null channel_id and closes the voice socket with 4014", function()
			local stub = discordStub.new({ clock = "virtual" })
			local ws = stub:createWebsocketServer()
			local voice = stub:createVoiceServer()
			local messages = {}
			local voiceMessages = {}
			local voiceClosed = {}

			openIdentified(stub, ws.url, messages)
			connect(voice.url, voiceMessages, voiceClosed)

			check.is_true(stub.clock:waitFor(function()
				return findOp(voiceMessages, 8)
			end, 30))

			ws:disconnectVoice("10")

			check.is_true(stub.clock:waitFor(function()
				return findEvent(messages, "VOICE_STATE_UPDATE") and voiceClosed[1] == 4014
			end, 30))
			check.equal((findEvent(messages, "VOICE_STATE_UPDATE") :: Message).payload.d.channel_id, nil)
			check.equal(findEvent(messages, "VOICE_SERVER_UPDATE"), nil)

			stub:stop()
		end)
	end)
end
