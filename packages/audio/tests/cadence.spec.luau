local frktest = require("../../../luau_packages/frktest")
local discordStub = require("../luau_packages/discord_stub")
local secret = require("../luau_packages/secret")
local stdPolyfills = require("../luau_packages/std_polyfills")
local voice = require("../luau_packages/voice")
local websocket = require("../luau_packages/websocket")

local audio = require("../src")

local GUILD_ID = "10"
local CHANNEL_ID = "20"
local USER_ID = "1"
local PACKET = "\248\0\0"
local SILENCE = "\248\255\254"
local PACKET_COUNT = 50
local OVERSLEEP_MILLISECONDS = 5
local START_MILLIS = 1000000
local WAIT_SECONDS = 1200

local test = frktest.test
local check = frktest.assert.check

if not stdPolyfills.runtime.capabilities().ffi then
	assert(
		not stdPolyfills.process.getEnv().DISCORD_LUAU_REQUIRE_FFI,
		"DISCORD_LUAU_REQUIRE_FFI is set but this runtime has no FFI"
	)

	return function()
		test.skip.suite("Audio cadence", function() end)
	end
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

local function joinedConnection(stub: discordStub.DiscordStub, gateway: any, world: World): voice.Connection
	world.manager = connectManager(stub, gateway.url)
	world.connection = voice.connection.new({
		shard = (world.manager :: websocket.Manager).shards[1],
		guildId = GUILD_ID,
		channelId = CHANNEL_ID,
		userId = USER_ID,
		logLevel = "Error",
	})

	local joining = world.connection :: voice.Connection

	assert(joining:joinAsync(WAIT_SECONDS):await():isOk(), "the join failed")

	return joining
end

local function teardown(world: World)
	if world.connection then
		world.connection:destroy()
	end

	if world.manager then
		for shardId in world.manager.shards do
			world.manager.shards[shardId]:forceClose()
		end
	end
end

local function injectedClock(plan: Plan): TestClock
	local testClock: TestClock = { now = START_MILLIS, waits = 0, waitStarts = {} }
	local adjustments = plan.adjustments or {}

	testClock.clock = {
		nowMillis = function(): number
			return testClock.now
		end,
		wait = function(seconds: number): number
			testClock.waits += 1
			table.insert(testClock.waitStarts, testClock.now)

			if plan.clockRaisesAfter and testClock.waits > plan.clockRaisesAfter then
				error("the clock broke", 0)
			end

			testClock.now += seconds * 1000 + OVERSLEEP_MILLISECONDS + (adjustments[testClock.waits] or 0)
			stdPolyfills.task.wait(0)

			return seconds
		end,
	}

	return testClock
end

local function countLines(lines: { string }, text: string): number
	local count = 0

	for _, line in lines do
		if string.find(line, text, 1, true) then
			count += 1
		end
	end

	return count
end

local function recordCalls(connection: voice.Connection, calls: { string })
	local recorded = connection :: any
	local setSpeakingAsync = connection.setSpeakingAsync
	local sendOpusAsync = connection.sendOpusAsync

	recorded.setSpeakingAsync = function(self: voice.Connection, speakingFlags: number)
		table.insert(calls, `speaking {speakingFlags}`)

		return setSpeakingAsync(self, speakingFlags)
	end
	recorded.sendOpusAsync = function(self: voice.Connection, audioFrame: buffer)
		table.insert(calls, if buffer.tostring(audioFrame) == SILENCE then "silence" else "packet")

		return sendOpusAsync(self, audioFrame)
	end
end

local function sourceFor(
	plan: Plan,
	clipIndex: number,
	packetCount: number,
	testClock: TestClock,
	readAt: { number }
): audio.Source
	return audio.fromOpus(function(): buffer?
		table.insert(readAt, testClock.now)

		if clipIndex == 1 and plan.sourceRaisesAfter and #readAt > plan.sourceRaisesAfter then
			error("the decoder broke", 0)
		end

		return if #readAt <= packetCount then buffer.fromstring(PACKET) else nil
	end)
end

local function playPlan(plan: Plan): Cadence
	local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
	local gateway = stub:createWebsocketServer()
	local world: World = {}
	local testClock = injectedClock(plan)
	local clips: { number } = plan.clips or { PACKET_COUNT }
	local cadence: Cadence = { reads = {}, lines = {}, calls = {}, waitStarts = testClock.waitStarts, results = {} }

	stub:createVoiceServer()

	check.equal(
		stub:runScenario(function()
			local connection = joinedConnection(stub, gateway, world)
			local player = audio.player.new(connection, { clock = testClock.clock, logLevel = "Debug" })

			recordCalls(connection, cadence.calls)
			player.logger:setSink(function(line: string)
				table.insert(cadence.lines, line)
			end)
			stdPolyfills.task.spawn(function()
				for clipIndex, packetCount in clips do
					local readAt = {}

					table.insert(cadence.reads, readAt)
					cadence.result =
						player:playAsync(sourceFor(plan, clipIndex, packetCount, testClock, readAt)):await()
					table.insert(cadence.results, cadence.result)
					testClock.now += plan.gapMillis or 0
				end

				cadence.finished = true
			end)

			check.is_true(stub.clock:waitFor(function()
				return cadence.finished
			end, WAIT_SECONDS))
		end, function()
			teardown(world)
		end),
		nil
	)

	return cadence
end

type World = { manager: websocket.Manager?, connection: voice.Connection? }
type TestClock = { now: number, waits: number, waitStarts: { number }, clock: audio.PlayerClock? }
type Plan = {
	adjustments: { [number]: number }?,
	clips: { number }?,
	gapMillis: number?,
	sourceRaisesAfter: number?,
	clockRaisesAfter: number?,
}
type Cadence = {
	reads: { { number } },
	lines: { string },
	calls: { string },
	waitStarts: { number },
	results: { any },
	result: any,
	finished: boolean?,
}

return function()
	test.suite("Audio cadence", function()
		test.case("packets follow absolute deadlines, so oversleeps do not add up", function()
			local cadence = playPlan({})
			local readAt = cadence.reads[1]

			check.equal(cadence.result:unwrapOk(), "finished")
			check.equal(readAt[PACKET_COUNT + 1] - readAt[1], 1005)
			check.equal(countLines(cadence.lines, "resetting the audio schedule"), 0)
		end)

		test.case("up to 100 ms behind, the next packets catch up without a reset", function()
			local cadence = playPlan({ adjustments = { [10] = 60 } })
			local readAt = cadence.reads[1]

			check.equal(cadence.result:unwrapOk(), "finished")
			check.equal(readAt[PACKET_COUNT + 1] - readAt[1], 1005)
			check.equal(countLines(cadence.lines, "resetting the audio schedule"), 0)
		end)

		test.case("a stall of more than 100 ms resets the schedule instead of bursting", function()
			local cadence = playPlan({ adjustments = { [10] = 150 } })
			local readAt = cadence.reads[1]

			check.equal(cadence.result:unwrapOk(), "finished")
			check.equal(countLines(cadence.lines, "resetting the audio schedule: 135 ms behind"), 1)
			check.equal(readAt[12] - readAt[11], 25)
		end)

		test.case("a clock that steps back resets the schedule instead of waiting it out", function()
			local cadence = playPlan({ adjustments = { [10] = -1000 } })
			local readAt = cadence.reads[1]

			check.equal(cadence.result:unwrapOk(), "finished")
			check.equal(countLines(cadence.lines, "resetting the audio schedule: 1015 ms ahead"), 1)
			check.equal(readAt[12] - readAt[11], 25)
		end)

		test.case("each playback starts its own schedule, so a gap between clips is not a stall", function()
			local cadence = playPlan({ clips = { 3, 3 }, gapMillis = 50 })

			check.equal(cadence.results[1]:unwrapOk(), "finished")
			check.equal(cadence.results[2]:unwrapOk(), "finished")
			check.equal(cadence.reads[2][2] - cadence.reads[2][1], 20 + OVERSLEEP_MILLISECONDS)
			check.equal(countLines(cadence.lines, "resetting the audio schedule"), 0)
		end)

		test.case("a source with no packets still paces its silence tail on a schedule", function()
			local cadence = playPlan({ clips = { 0 } })

			check.equal(cadence.result:unwrapOk(), "finished")
			check.equal(table.concat(cadence.calls, ","), `speaking 1,{string.rep("silence,", 5)}speaking 0`)
			check.equal(#cadence.waitStarts, 5)
			check.equal(cadence.waitStarts[5] - cadence.waitStarts[1], 85)
			check.equal(countLines(cadence.lines, "resetting the audio schedule"), 0)
		end)

		test.case("a clock that raises mid-play fails the playback with its error", function()
			local cadence = playPlan({ clockRaisesAfter = 4 })

			check.equal(tostring(cadence.result:unwrapErr()), "the clock broke")
		end)

		test.case("a clock that raises during the tail after an error keeps the original error", function()
			local cadence = playPlan({ sourceRaisesAfter = 3, clockRaisesAfter = 3 })

			check.equal(tostring(cadence.result:unwrapErr()), "audio source failed: the decoder broke")
			check.equal(countLines(cadence.lines, "silence tail after an error raised: the clock broke"), 1)
		end)

		test.case("the default clock reads std_polyfills when it is called, not when it was built", function()
			local player = audio.player.new(({} :: any) :: voice.Connection)
			local stub = discordStub.new({ clock = "virtual", polyfills = stdPolyfills })
			local startedAt = os.clock()
			local elapsedSeconds = 0
			local nowBefore = 0
			local nowAfter = 0

			check.equal(
				stub:runScenario(function()
					player.clock.wait(1)
					elapsedSeconds = os.clock() - startedAt
					nowBefore = player.clock.nowMillis()
					stub.clock:wait(10)
					nowAfter = player.clock.nowMillis()
				end),
				nil
			)
			check.lesser(elapsedSeconds, 0.5)
			check.greater_eq(nowAfter - nowBefore, 10000)
		end)
	end)
end
