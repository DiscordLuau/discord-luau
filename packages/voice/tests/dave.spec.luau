local frktest = require("../../../luau_packages/frktest")
local apiTypes = require("../luau_packages/api_types")
local discordStub = require("../luau_packages/discord_stub")
local logger = require("../luau_packages/logger")
local secret = require("../luau_packages/secret")
local stdPolyfills = require("../luau_packages/std_polyfills")
local websocket = require("../luau_packages/websocket")

local voice = require("../src")

local BOT_USER_ID = "1"
local MEMBER_USER_ID = "2"
local OTHER_MEMBER_USER_ID = "3"
local BOT_SSRC = 1234
local SPEAKER_SSRC = 4321
local GUILD_ID = "10"
local CHANNEL_ID = "20"
local KEY_PACKAGE = "stand-in key package"
local EXTERNAL_SENDER = "stand-in external sender"
local RTP_HEADER_SIZE = 12
local SECRET_KEY_SIZE = 32
local WAIT_SECONDS = 1200
local OPUS_FRAME = "ten bytes!"
local OPUS_SILENCE = "\248\255\254"

local test = frktest.test
local check = frktest.assert.check
local opcodes = apiTypes.voice.opcodes

if not stdPolyfills.runtime.capabilities().ffi then
	assert(
		not stdPolyfills.process.getEnv().DISCORD_LUAU_REQUIRE_FFI,
		"DISCORD_LUAU_REQUIRE_FFI is set but this runtime has no FFI"
	)

	return function()
		test.skip.suite("Voice DAVE framing", function() end)
	end
end

local function newRatchet(ledger: Ledger, userId: string): any
	local ratchet: any = { userId = userId, destroyCount = 0 }

	function ratchet.destroy()
		ratchet.destroyCount += 1
	end

	table.insert(ledger.ratchets, ratchet)

	return ratchet
end

local function newResult(scripted: ScriptedResult): any
	local added: { string } = scripted.added or {}
	local removed: { string } = scripted.removed or {}
	local memberIds: { string } = {}
	local signatures: { [string]: string } = {}

	for _, userId in added do
		table.insert(memberIds, userId)
		signatures[userId] = "signature"
	end

	for _, userId in removed do
		table.insert(memberIds, userId)
		signatures[userId] = ""
	end

	return {
		isFailed = function()
			return scripted.outcome == "failed"
		end,
		isIgnored = function()
			return scripted.outcome == "ignored"
		end,
		getRosterMemberIds = function()
			return table.clone(memberIds)
		end,
		getRosterMemberSignature = function(_, userId: string)
			local signature = signatures[userId]

			assert(signature, `{userId} is not in this result, and libdave aborts on that`)

			return buffer.fromstring(signature)
		end,
		destroy = function() end,
	}
end

local function newSession(ledger: Ledger, onMlsFailure: ((source: string, reason: string) -> ())?): any
	local session: any = {
		initCalls = {},
		externalSenders = {},
		protocolVersions = {},
		proposalRosters = {},
		welcomeRosters = {},
		commits = {},
		welcomes = {},
		hasGroup = false,
		destroyed = false,
	}

	local function takeResult(): ScriptedResult
		local scripted = table.remove(ledger.results, 1)

		assert(scripted, "the spec scripted no result for this commit or welcome")

		session.hasGroup = session.hasGroup or scripted.outcome == "accepted"

		return scripted
	end

	function session.init(_, version: number, groupId: string, userId: string)
		table.insert(session.initCalls, { version = version, groupId = groupId, userId = userId })
	end

	function session.setExternalSender(_, externalSender: buffer)
		table.insert(session.externalSenders, buffer.tostring(externalSender))
	end

	function session.setProtocolVersion(_, version: number)
		table.insert(session.protocolVersions, version)
	end

	function session.getMarshalledKeyPackage()
		return buffer.fromstring(ledger.keyPackage)
	end

	function session.processProposals(_, _proposals: buffer, recognizedUserIds: { string })
		table.insert(session.proposalRosters, table.clone(recognizedUserIds))

		return buffer.fromstring("commit and welcome")
	end

	function session.processCommit(_, commit: buffer)
		table.insert(session.commits, buffer.tostring(commit))

		return newResult(takeResult())
	end

	function session.processWelcome(_, welcome: buffer, recognizedUserIds: { string })
		local scripted = takeResult()

		table.insert(session.welcomes, buffer.tostring(welcome))
		table.insert(session.welcomeRosters, table.clone(recognizedUserIds))

		return if scripted.outcome == "accepted" then newResult(scripted) else nil
	end

	function session.getKeyRatchet(_, userId: string)
		return if session.hasGroup then newRatchet(ledger, userId) else nil
	end

	function session.destroy()
		session.destroyed = true
	end

	if onMlsFailure then
		table.insert(ledger.failureCallbacks, onMlsFailure)
	end

	table.insert(ledger.sessions, session)

	return session
end

local function newEncryptor(ledger: Ledger): any
	local encryptor: any = { ratchets = {}, passthrough = {}, encryptCalls = 0, destroyed = false }

	function encryptor.assignSsrcToCodec(_, ssrc: number)
		encryptor.ssrc = ssrc
	end

	function encryptor.setKeyRatchet(_, ratchet: any)
		table.insert(encryptor.ratchets, ratchet.userId)
	end

	function encryptor.setPassthroughMode(_, enabled: boolean)
		table.insert(encryptor.passthrough, enabled)
	end

	function encryptor.hasKeyRatchet()
		return #encryptor.ratchets > 0
	end

	function encryptor.encrypt(_, _mediaType: number, _ssrc: number, frame: buffer)
		encryptor.encryptCalls += 1

		return frame
	end

	function encryptor.destroy()
		encryptor.destroyed = true
	end

	table.insert(ledger.encryptors, encryptor)

	return encryptor
end

local function newDecryptor(ledger: Ledger): any
	local decryptor: any = { ratchets = {}, passthrough = {}, destroyed = false }

	function decryptor.transitionToKeyRatchet(_, ratchet: any)
		table.insert(decryptor.ratchets, ratchet.userId)
	end

	function decryptor.transitionToPassthroughMode(_, enabled: boolean)
		table.insert(decryptor.passthrough, enabled)
	end

	function decryptor.decrypt(_, _mediaType: number, frame: buffer)
		return frame
	end

	function decryptor.destroy()
		decryptor.destroyed = true
	end

	table.insert(ledger.decryptors, decryptor)

	return decryptor
end

local function useStandIns(manager: voice.DaveManager): Ledger
	local ledger: Ledger = {
		sessions = {},
		encryptors = {},
		decryptors = {},
		ratchets = {},
		failureCallbacks = {},
		results = {},
		keyPackage = KEY_PACKAGE,
	}

	manager.createSession = function(_authSessionId: string, onMlsFailure: ((source: string, reason: string) -> ())?)
		return newSession(ledger, onMlsFailure)
	end
	manager.createEncryptor = function()
		return newEncryptor(ledger)
	end
	manager.createDecryptor = function()
		return newDecryptor(ledger)
	end

	return ledger
end

local function connectManager(stub: discordStub.DiscordStub, url: string): websocket.Manager
	local manager = websocket.manager.new({
		token = secret.new("stub-token"),
		intents = 0,
		webSocketVersion = 10,
		reconnect = true,
	})

	manager.logger:setLogLevel("Warn")
	manager
		:connectAsync({
			url = url,
			shards = 1,
			session_start_limit = { total = 1000, remaining = 1000, reset_after = 0, max_concurrency = 1 },
		})
		:await()

	assert(
		stub.clock:waitFor(function()
			return manager.ready
		end, WAIT_SECONDS),
		"the gateway never became ready"
	)

	return manager
end

local function startWorld(
	stub: discordStub.DiscordStub,
	gateway: any,
	world: World,
	logLevel: any
): (voice.Connection, Ledger)
	local manager = connectManager(stub, gateway.url)
	local connection = voice.connection.new({
		shard = manager.shards[1],
		guildId = GUILD_ID,
		channelId = CHANNEL_ID,
		userId = BOT_USER_ID,
		logLevel = logLevel,
	})

	world.manager = manager
	world.connection = connection

	return connection, useStandIns(connection.dave)
end

local function run(stub: discordStub.DiscordStub, world: World, scenario: () -> ())
	check.equal(
		stub:runScenario(scenario, function()
			if world.connection then
				world.connection:destroy()
			end

			if world.manager then
				for shardId in world.manager.shards do
					world.manager.shards[shardId]:forceClose()
				end
			end
		end),
		nil
	)
end

local function keyPackagesSent(voiceServer: discordStub.VoiceServer): { string }
	local keyPackages = {}

	for _, record in voiceServer.received do
		if record.opcode == opcodes.DaveMlsKeyPackage then
			table.insert(keyPackages, buffer.tostring(record.payload.d :: buffer))
		end
	end

	return keyPackages
end

local function captureLogs(connection: voice.Connection, logLevel: logger.LogLevel): { string }
	local lines: { string } = {}

	connection.logger:setLogLevel(logLevel)
	connection.logger:setSink(function(message: string)
		table.insert(lines, message)
	end)

	return lines
end

local function captureWarnings(connection: voice.Connection): { string }
	return captureLogs(connection, "Warn")
end

local function countMatching(lines: { string }, text: string): number
	local count = 0

	for _, line in lines do
		if string.find(line, text, 1, true) then
			count += 1
		end
	end

	return count
end

local function findWarning(warnings: { string }, text: string): boolean
	for _, warning in warnings do
		if string.find(warning, text, 1, true) then
			return true
		end
	end

	return false
end

local function decodeSent(message: string | buffer): SentMessage
	if type(message) == "buffer" then
		return { op = buffer.readu8(message, 0), d = buffer.readstring(message, 1, buffer.len(message) - 1) }
	end

	local payload = stdPolyfills.serde.decode("json" :: any, message)

	return { op = payload.op, d = payload.d }
end

local function newStandInManager(): (voice.DaveManager, Ledger, Outbox)
	local manager = voice.dave.new(logger.new("DaveSpec", "Error"))
	local ledger = useStandIns(manager)
	local outbox: Outbox = { sent = {}, epochs = {} }

	manager.sendMessage = function(message: string | buffer)
		table.insert(outbox.sent, decodeSent(message))
	end
	manager.onTransitionExecuted = function(rosterSize: number)
		table.insert(outbox.epochs, rosterSize)
	end

	return manager, ledger, outbox
end

local function sentOf(outbox: Outbox, opcode: number): { any }
	local payloads = {}

	for _, message in outbox.sent do
		if message.op == opcode then
			table.insert(payloads, message.d)
		end
	end

	return payloads
end

local function receivedOf(voiceServer: discordStub.VoiceServer, opcode: number): { any }
	local payloads = {}

	for _, record in voiceServer.received do
		if record.opcode == opcode then
			table.insert(payloads, record.payload.d)
		end
	end

	return payloads
end

local function transitionPayload(transitionId: number, body: string): buffer
	local payload = buffer.create(2 + #body)

	buffer.writeu8(payload, 0, bit32.rshift(transitionId, 8))
	buffer.writeu8(payload, 1, bit32.band(transitionId, 0xFF))
	buffer.writestring(payload, 2, body)

	return payload
end

local function ratchetsOf(ledger: Ledger, userId: string): { any }
	local ratchets = {}

	for _, ratchet in ledger.ratchets do
		if ratchet.userId == userId then
			table.insert(ratchets, ratchet)
		end
	end

	return ratchets
end

local function last(list: { any }): any
	return list[#list]
end

local function daveOpsReceived(voiceServer: discordStub.VoiceServer): { number }
	local daveOps = {}

	for _, opcode in voiceServer:receivedOps() do
		if opcode >= opcodes.DaveProtocolTransitionReady then
			table.insert(daveOps, opcode)
		end
	end

	return daveOps
end

local function udpPayload(voiceServer: discordStub.VoiceServer, packet: buffer): string?
	local crypto = voice.rtp.new()

	crypto.secretKey = voiceServer.secretKey
	crypto.encryptionMode = voiceServer.selectedMode

	local opened = crypto:decryptRtp(packet, {}, {})

	return if opened then buffer.readstring(opened, RTP_HEADER_SIZE, buffer.len(opened) - RTP_HEADER_SIZE) else nil
end

local function speakerPacket(voiceServer: discordStub.VoiceServer, sequence: number, payload: string): buffer
	local crypto = voice.rtp.new()
	local rtpPacket = buffer.create(RTP_HEADER_SIZE + #payload)

	crypto.secretKey = voiceServer.secretKey
	crypto.encryptionMode = voiceServer.selectedMode
	buffer.writeu8(rtpPacket, 0, 0x80)
	buffer.writeu8(rtpPacket, 1, 0x78)
	buffer.writeu16(rtpPacket, 2, bit32.byteswap(sequence) // 0x10000)
	buffer.writeu32(rtpPacket, 8, bit32.byteswap(SPEAKER_SSRC))
	buffer.writestring(rtpPacket, RTP_HEADER_SIZE, payload)

	return (crypto:encryptRtp(rtpPacket, nil, SPEAKER_SSRC))
end

local function newFakeSocket(): any
	local fakeSocket: any = { sent = {}, holding = false, closed = false }

	function fakeSocket.send(packet: buffer)
		while fakeSocket.holding do
			stdPolyfills.task.wait()
		end

		table.insert(fakeSocket.sent, packet)
	end

	function fakeSocket.close()
		fakeSocket.closed = true
	end

	return fakeSocket
end

local function newOfflineTransport(lines: { string }): voice.UdpTransport
	local transportLogger = logger.new("UdpSpec", "Debug")
	local transport = voice.udp.new(transportLogger)

	transportLogger:setSink(function(message: string)
		table.insert(lines, message)
	end)

	return transport
end

local function newSessionCrypto(): voice.RtpCrypto
	local crypto = voice.rtp.new()

	crypto.secretKey = buffer.create(SECRET_KEY_SIZE)
	crypto.encryptionMode = "aead_xchacha20_poly1305_rtpsize"

	return crypto
end

local function findInError(result: any, text: string): number?
	return if result:isErr() then string.find(tostring(result:unwrapErr()), text, 1, true) else nil
end

local function watchMediaReady(manager: voice.DaveManager): { boolean }
	local changes: { boolean } = {}

	manager.onMediaReadyChanged = function(ready: boolean)
		table.insert(changes, ready)
	end

	return changes
end

type SentMessage = { op: number, d: any }
type Outbox = { sent: { SentMessage }, epochs: { number } }
type ScriptedResult = { outcome: "accepted" | "failed" | "ignored", added: { string }?, removed: { string }? }
type Ledger = {
	sessions: { any },
	encryptors: { any },
	decryptors: { any },
	ratchets: { any },
	failureCallbacks: { (source: string, reason: string) -> () },
	results: { ScriptedResult },
	keyPackage: string,
}
type World = { manager: websocket.Manager?, connection: voice.Connection? }

return function()
	test.suite("Voice DAVE framing", function()
		test.case("hands libdave the commit and the welcome after their two-byte transition ids", function()
			local manager, ledger = newStandInManager()

			manager:handleSessionDescription(1, CHANNEL_ID, BOT_USER_ID, BOT_SSRC)
			ledger.results = { { outcome = "ignored" }, { outcome = "accepted", added = { BOT_USER_ID } } }
			manager:handleCommitTransition(buffer.fromstring("\0\5\0\1\0\1\204"))
			manager:handleWelcome(buffer.fromstring("\0\1\0\2\170\187"))

			check.equal(ledger.sessions[1].commits[1], "\0\1\0\1\204")
			check.equal(ledger.sessions[1].welcomes[1], "\0\2\170\187")
		end)
	end)

	test.suite("Voice DAVE roster", function()
		test.case(
			"a commit adding two members, then one removing the first, keeps only the second's decryptor",
			function()
				local manager, ledger = newStandInManager()

				manager:handleSessionDescription(1, CHANNEL_ID, BOT_USER_ID, BOT_SSRC)
				manager:handleClientsConnect({ MEMBER_USER_ID, OTHER_MEMBER_USER_ID })
				ledger.results = {
					{ outcome = "accepted", added = { BOT_USER_ID, MEMBER_USER_ID, OTHER_MEMBER_USER_ID } },
					{ outcome = "accepted", removed = { MEMBER_USER_ID } },
				}
				manager:handleCommitTransition(transitionPayload(1, "commit"))

				local memberDecryptor: any = manager.daveDecryptors[MEMBER_USER_ID]
				local otherDecryptor: any = manager.daveDecryptors[OTHER_MEMBER_USER_ID]

				manager:handleCommitTransition(transitionPayload(2, "commit"))

				check.equal(manager.roster[BOT_USER_ID], true)
				check.equal(manager.roster[OTHER_MEMBER_USER_ID], true)
				check.equal(manager.roster[MEMBER_USER_ID], nil)
				check.is_true(memberDecryptor.destroyed)
				check.is_false(otherDecryptor.destroyed)
				check.equal(manager.daveDecryptors[MEMBER_USER_ID], nil)
			end
		)

		test.case("after a group reset, a welcome without a member destroys that member's decryptor", function()
			local manager, ledger = newStandInManager()

			manager:handleSessionDescription(1, CHANNEL_ID, BOT_USER_ID, BOT_SSRC)
			manager:handleClientsConnect({ MEMBER_USER_ID, OTHER_MEMBER_USER_ID })
			ledger.results = {
				{ outcome = "accepted", added = { BOT_USER_ID, MEMBER_USER_ID, OTHER_MEMBER_USER_ID } },
				{ outcome = "accepted", added = { BOT_USER_ID, OTHER_MEMBER_USER_ID } },
			}
			manager:handleCommitTransition(transitionPayload(1, "commit"))

			local memberDecryptor: any = manager.daveDecryptors[MEMBER_USER_ID]

			manager:handlePrepareEpoch({ protocol_version = 1, epoch = 1 })
			manager:handleWelcome(transitionPayload(2, "welcome"))

			check.equal(#ledger.sessions, 2)
			check.array.contains(
				ledger.sessions[2].welcomeRosters[1],
				{ BOT_USER_ID, MEMBER_USER_ID, OTHER_MEMBER_USER_ID }
			)
			check.is_true(memberDecryptor.destroyed)
			check.equal(manager.daveDecryptors[MEMBER_USER_ID], nil)
			check.not_nil(manager.daveDecryptors[OTHER_MEMBER_USER_ID])
		end)

		test.case("op 11 and op 13 keep the recognized set, which libdave gets with the bot", function()
			local manager, ledger = newStandInManager()

			manager:handleSessionDescription(1, CHANNEL_ID, BOT_USER_ID, BOT_SSRC)
			manager:handleClientsConnect({ MEMBER_USER_ID })
			manager:handleClientsConnect({ OTHER_MEMBER_USER_ID })

			check.equal(manager.recognizedUserIds[MEMBER_USER_ID], true)
			check.equal(manager.recognizedUserIds[OTHER_MEMBER_USER_ID], true)

			ledger.results = { { outcome = "accepted", added = { BOT_USER_ID, MEMBER_USER_ID } } }
			manager:handleWelcome(transitionPayload(1, "welcome"))

			local memberDecryptor: any = manager.daveDecryptors[MEMBER_USER_ID]

			manager:handleClientDisconnect(MEMBER_USER_ID)
			manager:handleProposals(buffer.fromstring("proposals"))

			check.equal(manager.recognizedUserIds[MEMBER_USER_ID], nil)
			check.equal(manager.recognizedUserIds[OTHER_MEMBER_USER_ID], true)
			check.is_true(memberDecryptor.destroyed)
			check.equal(manager.daveDecryptors[MEMBER_USER_ID], nil)
			check.array.contains(
				ledger.sessions[1].welcomeRosters[1],
				{ BOT_USER_ID, MEMBER_USER_ID, OTHER_MEMBER_USER_ID }
			)
			check.array.contains(ledger.sessions[1].proposalRosters[1], { BOT_USER_ID, OTHER_MEMBER_USER_ID })
			check.equal(#ledger.sessions[1].proposalRosters[1], 2)
		end)

		test.case("proposals send the commit and welcome (op 28) and fire no epoch event", function()
			local manager, _, outbox = newStandInManager()

			manager:handleSessionDescription(1, CHANNEL_ID, BOT_USER_ID, BOT_SSRC)
			manager:handleProposals(buffer.fromstring("proposals"))

			check.equal(sentOf(outbox, opcodes.DaveMlsCommitWelcome)[1], "commit and welcome")
			check.equal(#outbox.epochs, 0)
		end)
	end)

	test.suite("Voice DAVE key ratchets", function()
		test.case("after a welcome and its execute, every ratchet handed out was destroyed once", function()
			local manager, ledger = newStandInManager()

			manager:handleSessionDescription(1, CHANNEL_ID, BOT_USER_ID, BOT_SSRC)
			manager:handleClientsConnect({ MEMBER_USER_ID })
			ledger.results = { { outcome = "accepted", added = { BOT_USER_ID, MEMBER_USER_ID } } }
			manager:handleWelcome(transitionPayload(5, "welcome"))

			check.equal(#ledger.encryptors[1].ratchets, 0)

			manager:handleExecuteTransition({ transition_id = 5 })

			check.equal(#ledger.ratchets, 2)

			for _, ratchet in ledger.ratchets do
				check.equal(ratchet.destroyCount, 1)
			end

			check.array.equal(ledger.encryptors[1].ratchets, { BOT_USER_ID })
			check.array.equal(ledger.decryptors[1].ratchets, { MEMBER_USER_ID })
		end)

		test.case(
			"a second commit before op 22 destroys the bot's first ratchet, and the encryptor gets one",
			function()
				local manager, ledger = newStandInManager()

				manager:handleSessionDescription(1, CHANNEL_ID, BOT_USER_ID, BOT_SSRC)
				manager:handleClientsConnect({ MEMBER_USER_ID })
				ledger.results = {
					{ outcome = "accepted", added = { BOT_USER_ID, MEMBER_USER_ID } },
					{ outcome = "accepted" },
				}
				manager:handleCommitTransition(transitionPayload(1, "commit"))
				manager:handleCommitTransition(transitionPayload(2, "commit"))

				local selfRatchets = ratchetsOf(ledger, BOT_USER_ID)

				check.equal(#selfRatchets, 2)
				check.equal(selfRatchets[1].destroyCount, 1)
				check.equal(selfRatchets[2].destroyCount, 0)

				manager:handleExecuteTransition({ transition_id = 1 })
				manager:handleExecuteTransition({ transition_id = 2 })

				check.array.equal(ledger.encryptors[1].ratchets, { BOT_USER_ID })
				check.equal(selfRatchets[2].destroyCount, 1)
			end
		)

		test.case("a decryptor that cannot be created leaves the bot's key held, so cleanup destroys it", function()
			local manager, ledger = newStandInManager()

			manager:handleSessionDescription(1, CHANNEL_ID, BOT_USER_ID, BOT_SSRC)
			manager:handleClientsConnect({ MEMBER_USER_ID })
			manager.createDecryptor = function()
				error("stand-in decryptor failure")
			end
			ledger.results = { { outcome = "accepted", added = { BOT_USER_ID, MEMBER_USER_ID } } }

			check.should_error(function()
				manager:handleCommitTransition(transitionPayload(5, "commit"))

				return
			end)

			manager:cleanup()

			local selfRatchets = ratchetsOf(ledger, BOT_USER_ID)

			check.equal(#selfRatchets, 1)
			check.equal(selfRatchets[1].destroyCount, 1)
		end)
	end)

	test.suite("Voice DAVE transitions", function()
		test.case("op 21 to version 0 puts decryptors in passthrough at once and the version at op 22", function()
			local manager, ledger, outbox = newStandInManager()

			manager:handleSessionDescription(1, CHANNEL_ID, BOT_USER_ID, BOT_SSRC)
			manager:handleClientsConnect({ MEMBER_USER_ID })
			ledger.results = { { outcome = "accepted", added = { BOT_USER_ID, MEMBER_USER_ID } } }
			manager:handleCommitTransition(transitionPayload(0, "commit"))
			manager:handlePrepareTransition({ protocol_version = 0, transition_id = 7 })

			local memberDecryptor: any = manager.daveDecryptors[MEMBER_USER_ID]

			check.equal(last(memberDecryptor.passthrough), true)
			check.equal(sentOf(outbox, opcodes.DaveProtocolTransitionReady)[1].transition_id, 7)
			check.equal(manager.protocolVersion, 1)
			check.equal(manager.mediaProtocolVersion, 1)

			manager:handleExecuteTransition({ transition_id = 7 })

			check.equal(manager.protocolVersion, 0)
			check.equal(manager.mediaProtocolVersion, 0)
			check.equal(last(ledger.encryptors[1].passthrough), true)
			check.equal(last(ledger.sessions[1].protocolVersions), 0)
		end)

		test.case(
			"a commit for transition 5 holds the bot's key until op 22 for 5, which fires the epoch event",
			function()
				local manager, ledger, outbox = newStandInManager()

				manager:handleSessionDescription(1, CHANNEL_ID, BOT_USER_ID, BOT_SSRC)
				manager:handleClientsConnect({ MEMBER_USER_ID })
				ledger.results = { { outcome = "accepted", added = { BOT_USER_ID, MEMBER_USER_ID } } }
				manager:handleCommitTransition(transitionPayload(5, "commit"))

				check.equal(#ledger.encryptors[1].ratchets, 0)
				check.equal(sentOf(outbox, opcodes.DaveProtocolTransitionReady)[1].transition_id, 5)
				check.equal(#outbox.epochs, 0)

				manager:handleExecuteTransition({ transition_id = 5 })

				check.array.equal(ledger.encryptors[1].ratchets, { BOT_USER_ID })
				check.array.equal(outbox.epochs, { 2 })
				check.is_true(manager.selfRatchetApplied)
				check.equal(last(ledger.encryptors[1].passthrough), false)
				check.equal(last(ledger.sessions[1].protocolVersions), 1)
			end
		)

		test.case("a commit for transition 0 applies the bot's key at once and sends no op 23", function()
			local manager, ledger, outbox = newStandInManager()

			manager:handleSessionDescription(1, CHANNEL_ID, BOT_USER_ID, BOT_SSRC)
			ledger.results = { { outcome = "accepted", added = { BOT_USER_ID } } }
			manager:handleCommitTransition(transitionPayload(0, "commit"))

			check.array.equal(ledger.encryptors[1].ratchets, { BOT_USER_ID })
			check.equal(#sentOf(outbox, opcodes.DaveProtocolTransitionReady), 0)
			check.array.equal(outbox.epochs, { 1 })
		end)

		test.case("op 22 for an unknown transition changes nothing", function()
			local manager, ledger, outbox = newStandInManager()

			manager:handleSessionDescription(1, CHANNEL_ID, BOT_USER_ID, BOT_SSRC)
			manager:handleExecuteTransition({ transition_id = 9 })

			check.equal(#outbox.epochs, 0)
			check.equal(#ledger.encryptors[1].passthrough, 0)
			check.equal(#ledger.sessions[1].protocolVersions, 0)
			check.equal(manager.mediaProtocolVersion, 1)
		end)

		test.case("op 21 and op 22 without numeric ids are ignored with a warn", function()
			local manager, ledger, outbox = newStandInManager()
			local warnings: { string } = {}

			manager.logger:setLogLevel("Warn")
			manager.logger:setSink(function(message: string)
				table.insert(warnings, message)
			end)
			manager:handleSessionDescription(1, CHANNEL_ID, BOT_USER_ID, BOT_SSRC)
			manager:handlePrepareTransition({ transition_id = 0 })
			manager:handlePrepareTransition({ transition_id = 7, protocol_version = "one" })
			manager:handleExecuteTransition({ transition_id = "seven" })

			check.equal(#sentOf(outbox, opcodes.DaveProtocolTransitionReady), 0)
			check.equal(#outbox.epochs, 0)
			check.equal(#ledger.sessions[1].protocolVersions, 0)
			check.equal(manager.mediaProtocolVersion, 1)
			check.is_true(findWarning(warnings, "transition id 7 and protocol version one: both must be numbers"))
			check.is_true(findWarning(warnings, "execute transition with transition id seven: it must be a number"))
		end)

		test.case("a transition to version 0 destroys the bot's held key without applying it", function()
			local manager, ledger = newStandInManager()

			manager:handleSessionDescription(1, CHANNEL_ID, BOT_USER_ID, BOT_SSRC)
			ledger.results = { { outcome = "accepted", added = { BOT_USER_ID } } }
			manager:handleCommitTransition(transitionPayload(7, "commit"))
			manager:handlePrepareTransition({ protocol_version = 0, transition_id = 7 })
			manager:handleExecuteTransition({ transition_id = 7 })

			local selfRatchets = ratchetsOf(ledger, BOT_USER_ID)

			check.equal(#selfRatchets, 1)
			check.equal(selfRatchets[1].destroyCount, 1)
			check.equal(#ledger.encryptors[1].ratchets, 0)
			check.is_false(manager.selfRatchetApplied)
			check.equal(manager.pendingSelfRatchets[7], nil)
		end)

		test.case("a held key with no encryptor to take it is destroyed at execute", function()
			local manager, ledger = newStandInManager()

			manager:handleSessionDescription(1, CHANNEL_ID, BOT_USER_ID, BOT_SSRC)
			ledger.results = { { outcome = "accepted", added = { BOT_USER_ID } } }
			manager:handleCommitTransition(transitionPayload(7, "commit"))
			manager.daveEncryptor = nil
			manager:handleExecuteTransition({ transition_id = 7 })

			local selfRatchets = ratchetsOf(ledger, BOT_USER_ID)

			check.equal(#selfRatchets, 1)
			check.equal(selfRatchets[1].destroyCount, 1)
			check.is_false(manager.selfRatchetApplied)
			check.equal(manager.pendingSelfRatchets[7], nil)
		end)

		test.case(
			"a sole-member reset executes transition 0 with the bot alone and ends decryptor passthrough",
			function()
				local manager, ledger, outbox = newStandInManager()

				manager:handleSessionDescription(1, CHANNEL_ID, BOT_USER_ID, BOT_SSRC)
				manager:handleClientsConnect({ MEMBER_USER_ID })
				ledger.results = { { outcome = "accepted", added = { BOT_USER_ID, MEMBER_USER_ID } } }
				manager:handleCommitTransition(transitionPayload(0, "commit"))
				manager:handlePrepareTransition({ protocol_version = 0, transition_id = 4 })
				manager:handleExecuteTransition({ transition_id = 4 })

				local memberDecryptor: any = manager.daveDecryptors[MEMBER_USER_ID]

				check.equal(last(memberDecryptor.passthrough), true)

				manager:handlePrepareEpoch({ protocol_version = 1, epoch = 1 })
				manager:handlePrepareTransition({ protocol_version = 1, transition_id = 0 })

				check.equal(last(outbox.epochs), 1)
				check.equal(last(memberDecryptor.passthrough), false)
				check.equal(manager.mediaProtocolVersion, 1)
				check.equal(last(ledger.encryptors[2].passthrough), false)
				check.equal(#ledger.encryptors[2].ratchets, 0)
			end
		)

		test.case("a decryptor created while media is at protocol version 0 accepts plain frames", function()
			local manager, ledger = newStandInManager()

			manager:handleSessionDescription(0, CHANNEL_ID, BOT_USER_ID, BOT_SSRC)
			manager:handlePrepareEpoch({ protocol_version = 1, epoch = 1 })
			manager:handleClientsConnect({ MEMBER_USER_ID })
			ledger.results = { { outcome = "accepted", added = { BOT_USER_ID, MEMBER_USER_ID } } }
			manager:handleCommitTransition(transitionPayload(3, "commit"))

			check.array.equal(ledger.decryptors[1].passthrough, { true })

			manager:handleExecuteTransition({ transition_id = 3 })

			check.array.equal(ledger.decryptors[1].passthrough, { true, false })
		end)

		test.case("the voice gateway's commit and execute reach the manager, and op 13 forgets the member", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local voiceServer = stub:createVoiceServer({ daveProtocolVersion = 1 })
			local world: World = {}

			run(stub, world, function()
				local connection, ledger = startWorld(stub, gateway, world, "Error")
				local epochs = discordStub.recordEmits(connection.onDaveEpochTransition)

				ledger.results = { { outcome = "accepted", added = { BOT_USER_ID, MEMBER_USER_ID } } }

				check.is_true(connection:joinAsync(WAIT_SECONDS):await():isOk())

				voiceServer:sendClientsConnect({ MEMBER_USER_ID })
				voiceServer:sendBinary(opcodes.DaveMlsAnnounceCommitTransition, transitionPayload(5, "commit"))

				check.is_true(voiceServer:waitForOp(opcodes.DaveProtocolTransitionReady, WAIT_SECONDS))
				check.equal(receivedOf(voiceServer, opcodes.DaveProtocolTransitionReady)[1].transition_id, 5)
				check.equal(#epochs, 0)

				voiceServer:sendJson(opcodes.DaveProtocolExecuteTransition, { transition_id = 5 })

				check.is_true(stub.clock:waitFor(function()
					return #epochs == 1
				end, WAIT_SECONDS))
				check.equal(epochs[1][1], 2)

				voiceServer:sendClientDisconnect(MEMBER_USER_ID)

				check.is_true(stub.clock:waitFor(function()
					return ledger.decryptors[1].destroyed
				end, WAIT_SECONDS))
				check.equal(connection.dave.recognizedUserIds[MEMBER_USER_ID], nil)
			end)
		end)
	end)

	test.suite("Voice DAVE media readiness", function()
		test.case("Session Description makes media ready at once at version 0, and not above it", function()
			local plainManager = newStandInManager()
			local plainChanges = watchMediaReady(plainManager)
			local daveManager = newStandInManager()
			local daveChanges = watchMediaReady(daveManager)

			plainManager:handleSessionDescription(0, CHANNEL_ID, BOT_USER_ID, BOT_SSRC)
			daveManager:handleSessionDescription(1, CHANNEL_ID, BOT_USER_ID, BOT_SSRC)

			check.is_true(plainManager.mediaReady)
			check.array.equal(plainChanges, { true })
			check.is_false(daveManager.mediaReady)
			check.equal(#daveChanges, 0)
		end)

		test.case("the bot's key applied at op 22 makes media ready", function()
			local manager, ledger = newStandInManager()
			local changes = watchMediaReady(manager)

			manager:handleSessionDescription(1, CHANNEL_ID, BOT_USER_ID, BOT_SSRC)
			manager:handleClientsConnect({ MEMBER_USER_ID })
			ledger.results = { { outcome = "accepted", added = { BOT_USER_ID, MEMBER_USER_ID } } }
			manager:handleCommitTransition(transitionPayload(5, "commit"))

			check.is_false(manager.mediaReady)

			manager:handleExecuteTransition({ transition_id = 5 })

			check.is_true(manager.mediaReady)
			check.array.equal(changes, { true })
		end)

		test.case("an upgrade from version 0 keeps media ready and moves the media version only at op 22", function()
			local manager, ledger = newStandInManager()
			local changes = watchMediaReady(manager)

			manager:handleSessionDescription(0, CHANNEL_ID, BOT_USER_ID, BOT_SSRC)
			manager:handleClientsConnect({ MEMBER_USER_ID })
			manager:handlePrepareEpoch({ protocol_version = 1, epoch = 1 })

			check.is_true(manager.mediaReady)
			check.equal(manager.mediaProtocolVersion, 0)
			check.equal(manager.protocolVersion, 1)

			ledger.results = { { outcome = "accepted", added = { BOT_USER_ID, MEMBER_USER_ID } } }
			manager:handleCommitTransition(transitionPayload(3, "commit"))

			check.is_true(manager.mediaReady)
			check.equal(manager.mediaProtocolVersion, 0)

			manager:handleExecuteTransition({ transition_id = 3 })

			check.is_true(manager.mediaReady)
			check.equal(manager.mediaProtocolVersion, 1)
			check.array.equal(changes, { true })
		end)

		test.case("a group reset under DAVE pauses media, and a sole-member transition 0 keeps it paused", function()
			local manager, ledger = newStandInManager()
			local changes = watchMediaReady(manager)

			manager:handleSessionDescription(1, CHANNEL_ID, BOT_USER_ID, BOT_SSRC)
			ledger.results = { { outcome = "accepted", added = { BOT_USER_ID } } }
			manager:handleCommitTransition(transitionPayload(0, "commit"))

			check.is_true(manager.mediaReady)

			manager:handlePrepareEpoch({ protocol_version = 1, epoch = 1 })

			check.is_false(manager.mediaReady)

			manager:handlePrepareTransition({ protocol_version = 1, transition_id = 0 })

			check.is_false(manager.mediaReady)
			check.array.equal(changes, { true, false })
		end)

		test.case("the epoch listener sees media readiness already updated by the transition", function()
			local upgradedManager = newStandInManager()
			local keyedManager, keyedLedger = newStandInManager()
			local upgradedSeen: { boolean } = {}
			local keyedSeen: { boolean } = {}

			upgradedManager.onTransitionExecuted = function()
				table.insert(upgradedSeen, upgradedManager.mediaReady)
			end
			keyedManager.onTransitionExecuted = function()
				table.insert(keyedSeen, keyedManager.mediaReady)
			end

			upgradedManager:handleSessionDescription(0, CHANNEL_ID, BOT_USER_ID, BOT_SSRC)
			upgradedManager:handlePrepareTransition({ transition_id = 4, protocol_version = 1 })
			upgradedManager:handleExecuteTransition({ transition_id = 4 })
			keyedManager:handleSessionDescription(1, CHANNEL_ID, BOT_USER_ID, BOT_SSRC)
			keyedLedger.results = { { outcome = "accepted", added = { BOT_USER_ID } } }
			keyedManager:handleCommitTransition(transitionPayload(5, "commit"))
			keyedManager:handleExecuteTransition({ transition_id = 5 })

			check.array.equal(upgradedSeen, { false })
			check.array.equal(keyedSeen, { true })
		end)

		test.case("cleanup leaves media not ready and no media version", function()
			local manager = newStandInManager()
			local changes = watchMediaReady(manager)

			manager:handleSessionDescription(0, CHANNEL_ID, BOT_USER_ID, BOT_SSRC)
			manager:cleanup()

			check.is_false(manager.mediaReady)
			check.equal(manager.mediaProtocolVersion, nil)
			check.array.equal(changes, { true, false })
		end)

		test.case(
			"without DAVE, onMediaReady fires once at Session Description and the wait resolves at once",
			function()
				local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
				local gateway = stub:createWebsocketServer()
				local world: World = {}

				stub:createVoiceServer()

				run(stub, world, function()
					local connection = startWorld(stub, gateway, world, "Error")
					local mediaReadyEmits = discordStub.recordEmits(connection.onMediaReady)

					check.is_true(connection:joinAsync(WAIT_SECONDS):await():isOk())
					check.equal(#mediaReadyEmits, 1)
					check.is_true(connection:awaitMediaReadyAsync(1):await():isOk())

					stub.clock:wait(1)

					check.equal(#mediaReadyEmits, 1)
				end)
			end
		)

		test.case("awaitMediaReadyAsync tells a timeout from a close", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local world: World = {}
			local closedWait: { result: any } = {}

			stub:createVoiceServer({ daveProtocolVersion = 1 })

			run(stub, world, function()
				local connection = startWorld(stub, gateway, world, "Error")

				check.is_true(connection:joinAsync(WAIT_SECONDS):await():isOk())

				local timedOut = connection:awaitMediaReadyAsync(2):await()

				check.not_nil(findInError(timedOut, "timed out waiting for DAVE media readiness"))

				stdPolyfills.task.spawn(function()
					closedWait.result = connection:awaitMediaReadyAsync():await()
				end)
				connection:destroy()

				check.is_true(stub.clock:waitFor(function()
					return closedWait.result
				end, WAIT_SECONDS))
				check.not_nil(
					findInError(closedWait.result, "voice connection closed: the voice connection was destroyed")
				)
			end)
		end)
	end)

	test.suite("Voice DAVE recovery", function()
		test.case("an ignored commit only logs", function()
			local manager, ledger, outbox = newStandInManager()

			manager:handleSessionDescription(1, CHANNEL_ID, BOT_USER_ID, BOT_SSRC)
			ledger.results = { { outcome = "ignored" } }
			manager:handleCommitTransition(transitionPayload(6, "commit"))

			check.equal(#ledger.sessions, 1)
			check.equal(#sentOf(outbox, opcodes.DaveMlsInvalidCommitWelcome), 0)
			check.equal(#sentOf(outbox, opcodes.DaveMlsKeyPackage), 1)
		end)

		test.case(
			"a failed commit sends op 31 with its transition id, then a new key package, and pauses media",
			function()
				local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
				local gateway = stub:createWebsocketServer()
				local voiceServer = stub:createVoiceServer({ daveProtocolVersion = 1 })
				local world: World = {}

				run(stub, world, function()
					local connection, ledger = startWorld(stub, gateway, world, "Error")

					ledger.results = { { outcome = "accepted", added = { BOT_USER_ID } }, { outcome = "failed" } }

					check.is_true(connection:joinAsync(WAIT_SECONDS):await():isOk())

					voiceServer:sendBinary(opcodes.DaveMlsExternalSenderPackage, buffer.fromstring(EXTERNAL_SENDER))
					voiceServer:sendBinary(opcodes.DaveMlsAnnounceCommitTransition, transitionPayload(0, "commit"))

					check.is_true(stub.clock:waitFor(function()
						return connection.dave.mediaReady
					end, WAIT_SECONDS))

					voiceServer:sendBinary(opcodes.DaveMlsAnnounceCommitTransition, transitionPayload(7, "commit"))

					check.is_true(stub.clock:waitFor(function()
						return #keyPackagesSent(voiceServer) == 2
					end, WAIT_SECONDS))
					check.array.equal(daveOpsReceived(voiceServer), {
						opcodes.DaveMlsKeyPackage,
						opcodes.DaveMlsInvalidCommitWelcome,
						opcodes.DaveMlsKeyPackage,
					})
					check.equal(receivedOf(voiceServer, opcodes.DaveMlsInvalidCommitWelcome)[1].transition_id, 7)
					check.is_false(connection.dave.mediaReady)
					check.equal(#ledger.sessions, 2)
					check.is_true(ledger.sessions[1].destroyed)
					check.equal(ledger.sessions[2].initCalls[1].version, 1)
					check.equal(ledger.sessions[2].initCalls[1].groupId, CHANNEL_ID)
					check.equal(ledger.sessions[2].initCalls[1].userId, BOT_USER_ID)
					check.equal(ledger.sessions[2].externalSenders[1], EXTERNAL_SENDER)
				end)
			end
		)

		test.case("a burst of failures sends one op 31, and after a success the next failure sends another", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local voiceServer = stub:createVoiceServer({ daveProtocolVersion = 1 })
			local world: World = {}

			run(stub, world, function()
				local connection, ledger = startWorld(stub, gateway, world, "Error")

				ledger.results = {
					{ outcome = "failed" },
					{ outcome = "failed" },
					{ outcome = "accepted", added = { BOT_USER_ID } },
					{ outcome = "failed" },
				}

				check.is_true(connection:joinAsync(WAIT_SECONDS):await():isOk())

				voiceServer:sendBinary(opcodes.DaveMlsAnnounceCommitTransition, transitionPayload(1, "commit"))
				voiceServer:sendBinary(opcodes.DaveMlsWelcome, transitionPayload(2, "welcome"))

				check.is_true(stub.clock:waitFor(function()
					return ledger.sessions[2] and #ledger.sessions[2].welcomes == 1
				end, WAIT_SECONDS))

				stub.clock:wait(1)

				check.equal(#receivedOf(voiceServer, opcodes.DaveMlsInvalidCommitWelcome), 1)
				check.equal(#keyPackagesSent(voiceServer), 2)

				voiceServer:sendBinary(opcodes.DaveMlsWelcome, transitionPayload(3, "welcome"))
				voiceServer:sendBinary(opcodes.DaveMlsAnnounceCommitTransition, transitionPayload(4, "commit"))

				check.is_true(stub.clock:waitFor(function()
					return #keyPackagesSent(voiceServer) == 3
				end, WAIT_SECONDS))

				local invalidTransitions = receivedOf(voiceServer, opcodes.DaveMlsInvalidCommitWelcome)

				check.equal(#invalidTransitions, 2)
				check.equal(invalidTransitions[1].transition_id, 1)
				check.equal(invalidTransitions[2].transition_id, 4)
			end)
		end)
	end)

	test.suite("Voice DAVE sending", function()
		test.case(
			"a send created before a group reset and run after it sends silence, not the old encryptor's",
			function()
				local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
				local gateway = stub:createWebsocketServer()
				local voiceServer = stub:createVoiceServer({ daveProtocolVersion = 1 })
				local world: World = {}

				run(stub, world, function()
					local connection, ledger = startWorld(stub, gateway, world, "Error")

					ledger.results = { { outcome = "accepted", added = { BOT_USER_ID } } }

					check.is_true(connection:joinAsync(WAIT_SECONDS):await():isOk())

					voiceServer:sendBinary(opcodes.DaveMlsAnnounceCommitTransition, transitionPayload(0, "commit"))

					check.is_true(stub.clock:waitFor(function()
						return connection.dave.mediaReady
					end, WAIT_SECONDS))

					local pendingSend = connection:sendOpusAsync(buffer.fromstring(OPUS_FRAME))
					local packetsBefore = #voiceServer.udpServer.packets

					voiceServer:sendJson(opcodes.DaveProtocolPrepareEpoch, { protocol_version = 1, epoch = 1 })

					check.is_true(stub.clock:waitFor(function()
						return #keyPackagesSent(voiceServer) == 2
					end, WAIT_SECONDS))
					check.is_true(pendingSend:await():isOk())
					check.is_true(stub.clock:waitFor(function()
						return #voiceServer.udpServer.packets > packetsBefore
					end, WAIT_SECONDS))
					check.equal(udpPayload(voiceServer, voiceServer.udpServer.packets[packetsBefore + 1]), OPUS_SILENCE)
					check.equal(ledger.encryptors[1].encryptCalls, 0)
					check.is_true(ledger.encryptors[1].destroyed)
				end)
			end
		)

		test.case("a send whose DAVE manager has no media protocol version yet fails and sends nothing", function()
			local lines: { string } = {}
			local transport = newOfflineTransport(lines)
			local daveManager = voice.dave.new(transport.logger)
			local fakeSocket = newFakeSocket()

			transport.udpSocket = fakeSocket
			transport.ssrc = BOT_SSRC

			local result =
				transport:sendOpusAsync(buffer.fromstring(OPUS_FRAME), newSessionCrypto(), daveManager):await()

			check.not_nil(findInError(result, "cannot send audio: the DAVE protocol version is not known yet"))
			check.equal(#fakeSocket.sent, 0)
		end)

		test.case("a silent send in flight across cleanup does not hide the next session's first gap", function()
			local lines: { string } = {}
			local transport = newOfflineTransport(lines)
			local daveManager = voice.dave.new(transport.logger)
			local heldSocket = newFakeSocket()
			local nextSocket = newFakeSocket()
			local crypto = newSessionCrypto()

			daveManager.mediaProtocolVersion = 1
			heldSocket.holding = true
			transport.udpSocket = heldSocket
			transport.ssrc = BOT_SSRC

			local heldSend = transport:sendOpusAsync(buffer.fromstring(OPUS_FRAME), crypto, daveManager)

			heldSend:poll()
			transport:cleanup()
			heldSocket.holding = false

			check.is_true(heldSend:await():isOk())
			check.is_false(transport.substitutingSilence)

			transport.udpSocket = nextSocket
			transport.ssrc = BOT_SSRC

			check.is_true(transport:sendOpusAsync(buffer.fromstring(OPUS_FRAME), crypto, daveManager):await():isOk())
			check.equal(countMatching(lines, "sending Opus silence in place of audio"), 2)
			check.equal(#heldSocket.sent, 1)
			check.equal(#nextSocket.sent, 1)
		end)

		test.case("silence is logged at debug once per gap, and a closed session's gap does not carry over", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local voiceServer = stub:createVoiceServer({ daveProtocolVersion = 1 })
			local world: World = {}

			run(stub, world, function()
				local connection, ledger = startWorld(stub, gateway, world, "Error")
				local logs = captureLogs(connection, "Debug")
				local silenceLine = "sending Opus silence in place of audio"

				ledger.results = { { outcome = "accepted", added = { BOT_USER_ID } } }

				check.is_true(connection:joinAsync(WAIT_SECONDS):await():isOk())
				check.is_true(connection:sendOpusAsync(buffer.fromstring(OPUS_FRAME)):await():isOk())
				check.is_true(connection:sendOpusAsync(buffer.fromstring(OPUS_FRAME)):await():isOk())
				check.equal(countMatching(logs, silenceLine), 1)

				voiceServer:sendBinary(opcodes.DaveMlsAnnounceCommitTransition, transitionPayload(0, "commit"))

				check.is_true(stub.clock:waitFor(function()
					return connection.dave.mediaReady
				end, WAIT_SECONDS))
				check.is_true(connection:sendOpusAsync(buffer.fromstring(OPUS_FRAME)):await():isOk())
				check.equal(ledger.encryptors[1].encryptCalls, 1)

				voiceServer:sendJson(opcodes.DaveProtocolPrepareEpoch, { protocol_version = 1, epoch = 1 })

				check.is_true(stub.clock:waitFor(function()
					return #keyPackagesSent(voiceServer) == 2
				end, WAIT_SECONDS))
				check.is_true(connection:sendOpusAsync(buffer.fromstring(OPUS_FRAME)):await():isOk())
				check.is_true(connection:sendOpusAsync(buffer.fromstring(OPUS_FRAME)):await():isOk())
				check.equal(countMatching(logs, silenceLine), 2)
				check.is_true(connection.udp.substitutingSilence)

				connection:destroy()

				check.is_false(connection.udp.substitutingSilence)
			end)
		end)
	end)

	test.suite("Voice DAVE receiving", function()
		test.case(
			"a plain frame from a sender with no decryptor is dropped at debug, but silence passes, and plain frames pass while a move to version 0 is pending",
			function()
				local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
				local gateway = stub:createWebsocketServer()
				local voiceServer = stub:createVoiceServer({ daveProtocolVersion = 1 })
				local world: World = {}

				run(stub, world, function()
					local connection = startWorld(stub, gateway, world, "Error")
					local logs = captureLogs(connection, "Debug")
					local received: { [number]: string } = {}
					local dropLine = `dropping an RTP packet: it is a plain frame from ssrc {SPEAKER_SSRC}`

					connection.udp.onAudioPacket = function(_ssrc: number, sequence: number, audioFrame: buffer)
						received[sequence] = buffer.tostring(audioFrame)
					end

					check.is_true(connection:joinAsync(WAIT_SECONDS):await():isOk())

					voiceServer.udpServer:send(speakerPacket(voiceServer, 100, OPUS_FRAME))
					voiceServer.udpServer:send(speakerPacket(voiceServer, 101, OPUS_SILENCE))

					check.is_true(stub.clock:waitFor(function()
						return received[101] and countMatching(logs, dropLine) == 1
					end, WAIT_SECONDS))
					check.equal(received[101], OPUS_SILENCE)
					check.equal(received[100], nil)

					voiceServer:sendJson(
						opcodes.DaveProtocolPrepareTransition,
						{ transition_id = 3, protocol_version = 0 }
					)

					check.is_true(voiceServer:waitForOp(opcodes.DaveProtocolTransitionReady, WAIT_SECONDS))

					voiceServer.udpServer:send(speakerPacket(voiceServer, 102, OPUS_FRAME))

					check.is_true(stub.clock:waitFor(function()
						return received[102]
					end, WAIT_SECONDS))
					check.equal(received[102], OPUS_FRAME)
					check.equal(countMatching(logs, dropLine), 1)
				end)
			end
		)
	end)

	test.suite("Voice DAVE key packages", function()
		test.case("Session Description above version 0 sends a key package at once, and op 25 sends none", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local voiceServer = stub:createVoiceServer({ daveProtocolVersion = 1 })
			local world: World = {}

			run(stub, world, function()
				local connection, ledger = startWorld(stub, gateway, world, "Error")

				check.is_true(connection:joinAsync(WAIT_SECONDS):await():isOk())
				check.is_true(voiceServer:waitForOp(opcodes.DaveMlsKeyPackage, WAIT_SECONDS))
				check.equal(keyPackagesSent(voiceServer)[1], KEY_PACKAGE)
				check.equal(#ledger.sessions, 1)
				check.equal(ledger.sessions[1].initCalls[1].version, 1)
				check.equal(ledger.sessions[1].initCalls[1].groupId, CHANNEL_ID)
				check.equal(ledger.sessions[1].initCalls[1].userId, BOT_USER_ID)
				check.equal(ledger.encryptors[1].ssrc, voiceServer.ssrc)

				voiceServer:sendBinary(opcodes.DaveMlsExternalSenderPackage, buffer.fromstring(EXTERNAL_SENDER))

				check.is_true(stub.clock:waitFor(function()
					return #ledger.sessions[1].externalSenders == 1
				end, WAIT_SECONDS))

				stub.clock:wait(1)

				check.equal(ledger.sessions[1].externalSenders[1], EXTERNAL_SENDER)
				check.equal(#keyPackagesSent(voiceServer), 1)
			end)
		end)

		test.case("op 24 resets the group only for epoch 1, applying the stored external sender", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local voiceServer = stub:createVoiceServer({ daveProtocolVersion = 1 })
			local world: World = {}

			run(stub, world, function()
				local connection, ledger = startWorld(stub, gateway, world, "Error")

				check.is_true(connection:joinAsync(WAIT_SECONDS):await():isOk())
				check.is_true(voiceServer:waitForOp(opcodes.DaveMlsKeyPackage, WAIT_SECONDS))

				voiceServer:sendBinary(opcodes.DaveMlsExternalSenderPackage, buffer.fromstring(EXTERNAL_SENDER))
				voiceServer:sendJson(opcodes.DaveProtocolPrepareEpoch, { protocol_version = 1, epoch = 2 })
				stub.clock:wait(1)

				check.equal(#ledger.sessions, 1)
				check.equal(#keyPackagesSent(voiceServer), 1)

				voiceServer:sendJson(opcodes.DaveProtocolPrepareEpoch, { protocol_version = 1, epoch = 1 })

				check.is_true(stub.clock:waitFor(function()
					return #keyPackagesSent(voiceServer) == 2
				end, WAIT_SECONDS))
				check.equal(#ledger.sessions, 2)
				check.is_true(ledger.sessions[1].destroyed)
				check.equal(ledger.sessions[2].initCalls[1].version, 1)
				check.equal(ledger.sessions[2].initCalls[1].groupId, CHANNEL_ID)
				check.equal(ledger.sessions[2].externalSenders[1], EXTERNAL_SENDER)
				check.equal(#ledger.encryptors, 2)
				check.is_true(ledger.encryptors[1].destroyed)

				voiceServer:sendJson(opcodes.DaveProtocolPrepareEpoch, { protocol_version = 1, epoch = "1" })

				check.is_true(stub.clock:waitFor(function()
					return #keyPackagesSent(voiceServer) == 3
				end, WAIT_SECONDS))
			end)
		end)

		test.case("op 24 with epoch 1 and no protocol version resets the group at the session's version", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local voiceServer = stub:createVoiceServer({ daveProtocolVersion = 1 })
			local world: World = {}

			run(stub, world, function()
				local connection, ledger = startWorld(stub, gateway, world, "Warn")
				local warnings = captureWarnings(connection)

				check.is_true(connection:joinAsync(WAIT_SECONDS):await():isOk())
				check.is_true(voiceServer:waitForOp(opcodes.DaveMlsKeyPackage, WAIT_SECONDS))

				voiceServer:sendJson(opcodes.DaveProtocolPrepareEpoch, { epoch = 1 })

				check.is_true(stub.clock:waitFor(function()
					return #keyPackagesSent(voiceServer) == 2
				end, WAIT_SECONDS))
				check.equal(#ledger.sessions, 2)
				check.is_true(ledger.sessions[1].destroyed)
				check.equal(ledger.sessions[2].initCalls[1].version, 1)
				check.equal(connection.dave.protocolVersion, 1)
				check.is_true(findWarning(warnings, "using the session's protocol version 1"))
			end)
		end)

		test.case("an empty key package is not sent, and an MLS failure is logged at warn", function()
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local gateway = stub:createWebsocketServer()
			local voiceServer = stub:createVoiceServer({ daveProtocolVersion = 1 })
			local world: World = {}

			run(stub, world, function()
				local connection, ledger = startWorld(stub, gateway, world, "Warn")
				local warnings = captureWarnings(connection)

				ledger.keyPackage = ""

				check.is_true(connection:joinAsync(WAIT_SECONDS):await():isOk())
				check.is_true(stub.clock:waitFor(function()
					return findWarning(warnings, "DAVE key package is empty")
				end, WAIT_SECONDS))
				check.equal(#keyPackagesSent(voiceServer), 0)

				ledger.failureCallbacks[1]("ProcessCommit", "the commit did not parse")

				check.is_true(findWarning(warnings, "DAVE MLS failure in ProcessCommit: the commit did not parse"))
			end)
		end)
	end)
end
