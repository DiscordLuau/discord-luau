--[=[
	@class Audio.Player
	@__index Prototype

	Plays audio sources on one voice connection, one at a time. `playAsync` sends Speaking, then each packet of the
	source paced by its own duration, then five silence frames and Speaking 0, and resolves `"finished"`, or
	`"stopped"` after `stop`. One player per connection plays at a time; a second `playAsync`, on this player or on
	another player of the same connection, fails at once and leaves the running playback alone.

	While the connection resumes or rejoins, the playback waits, woken by the connection's `onReady`, `onResumed` and
	`onClosed`. On each new session it waits up to `mediaWaitSeconds` for DAVE media readiness, then sends Speaking
	again; until media is ready, voice sends Opus silence in place of every packet, so nothing leaves unencrypted.

	A player is bound to one `Connection`. After that connection closes, a new join makes a new `Connection`, which
	needs a new player. Sources must return quickly: a `read` that takes longer than a frame leaves a gap in the audio,
	and a `read` that never returns holds the playback, which `stop` cannot end.

	A stream source from `audio.fromStream` never blocks a read. While it is `starved`, before it has buffered enough
	and whenever it stalls, the playback sends its silence tail and Speaking 0 if Speaking went out, then polls the
	source every 20 ms, and speaks again on a fresh schedule once the source has audio.
]=]

--[=[
	@prop connection voice.Connection
	@within Audio.Player

	The voice connection the player sends on.
]=]

--[=[
	@prop speakingFlags number
	@within Audio.Player

	The Speaking flags sent before audio: 1 (Microphone) by default, never 0.
]=]

--[=[
	@prop silenceFrames number
	@within Audio.Player

	How many Opus silence frames end a playback, 5 by default.
]=]

--[=[
	@prop mediaWaitSeconds number
	@within Audio.Player

	How long a playback waits for DAVE media readiness before Speaking on each new session, 5 seconds by default.
]=]

--[=[
	@prop clock PlayerClock
	@within Audio.Player

	Where the pace reads the time and waits. The default reads `std_polyfills`' `datetime.now` and `task.wait` on
	every call, so a clock swapped in later, such as `discord_stub`'s virtual clock, is the one it uses.
]=]

--[=[
	@prop logger logger.Logger
	@within Audio.Player

	The player's logger, named `AudioPlayer`, at `Info` unless `logLevel` says otherwise.
]=]

--[=[
	@prop playing boolean
	@within Audio.Player

	Whether a playback runs, from its start checks until its silence tail and cleanup end.
]=]

--[=[
	@prop ending boolean
	@within Audio.Player

	Whether the running playback has reached its end and is sending its silence tail; `stop` does nothing then.
]=]

--[=[
	@prop stopRequested boolean
	@within Audio.Player

	Whether `stop` asked the running playback to end. A playback clears it when it starts.
]=]

--[=[
	@prop readyCount number
	@within Audio.Player

	How many times the connection became ready since the running playback started.
]=]

--[=[
	@prop spokenReadyCount number?
	@within Audio.Player

	The `readyCount` that Speaking last went out on, nil while Speaking is off.
]=]

--[=[
	@prop startMillis number?
	@within Audio.Player

	The clock time the schedule starts from: set just before the first paced send of a playback, and moved by each
	schedule reset.
]=]

--[=[
	@prop elapsedSamples number
	@within Audio.Player

	The samples sent since `startMillis`; the next deadline is `startMillis + elapsedSamples / 48` milliseconds.
]=]

--[=[
	@prop packetsSent number
	@within Audio.Player

	How many of the source's packets the running or last playback sent.
]=]

--[=[
	@prop silenceFramesSent number
	@within Audio.Player

	How many silence frames the running or last playback sent.
]=]

--[=[
	@prop onWake emitter.Emitter<()>
	@within Audio.Player
	@private

	Wakes the playback's thread on the next scheduler step after the connection becomes ready, resumes or closes, or
	after `stop`.
]=]

--[=[
	@prop listenerDisconnects { () -> () }
	@within Audio.Player
	@private

	Disconnects the running playback's listeners on the connection's `onReady`, `onResumed` and `onClosed`; empty
	while nothing plays.
]=]

local emitter = require("../luau_packages/emitter")
local future = require("../luau_packages/future")
local logger = require("../luau_packages/logger")
local stdPolyfills = require("../luau_packages/std_polyfills")
local voice = require("../luau_packages/voice")

local audioSource = require("./source")

local SILENCE_FRAME = buffer.fromstring("\248\255\254")
local SILENCE_FRAME_SAMPLES = 960
local SAMPLES_PER_MILLISECOND = 48
local SCHEDULE_SLACK_MILLISECONDS = 100
local DEFAULT_SPEAKING_FLAGS = 1
local DEFAULT_SILENCE_FRAMES = 5
local DEFAULT_MEDIA_WAIT_SECONDS = 5
local STARVED_POLL_SECONDS = 0.02

local DEFAULT_CLOCK: PlayerClock = {
	nowMillis = function(): number
		return stdPolyfills.datetime.now().unixTimestampMillis
	end,
	wait = function(seconds: number): number
		return stdPolyfills.task.wait(seconds)
	end,
}

local playingPlayers: { [voice.Connection]: Player } = {}

local Player = {}

Player.Interface = {}
Player.Prototype = {}

local function readPacket(source: Source): buffer?
	local read, packet = pcall(function()
		return source:read()
	end)

	if not read then
		error(`audio source failed: {packet}`, 0)
	end

	return packet
end

--[=[
	@within Audio.Player
	@private

	Runs the start checks, claims the source and resets the playback state. Raises when a check fails, before anything
	is claimed.
]=]
function Player.Prototype.start(self: Player, source: Source)
	local connection = self.connection

	if self.playing then
		error(`audio player is already playing; await the previous playAsync future first`, 0)
	end

	if playingPlayers[connection] then
		error(`another audio player is playing on this voice connection`, 0)
	end

	if connection.status == "idle" then
		error(`voice connection was never joined`, 0)
	end

	if connection.status == "closed" then
		error(`voice connection closed: {connection.closeDetail}`, 0)
	end

	source:claim()

	self.playing = true
	playingPlayers[connection] = self
	self.stopRequested = false
	self.ending = false
	self.readyCount = 0
	self.spokenReadyCount = nil
	self.startMillis = nil
	self.elapsedSamples = 0
	self.packetsSent = 0
	self.silenceFramesSent = 0
	self.listenerDisconnects = {
		connection.onReady:listen(function()
			self:countSession()
		end),
		connection.onResumed:listen(function()
			self:countSession()
		end),
		connection.onClosed:listen(function()
			self:wake()
		end),
	}
end

--[=[
	@within Audio.Player
	@private

	Wakes the playback's thread on the next scheduler step, so it never runs inside the caller's stack, as
	`Connection` wakes its supervisor.
]=]
function Player.Prototype.wake(self: Player)
	stdPolyfills.task.defer(function()
		self.onWake:invoke()
	end)
end

--[=[
	@within Audio.Player
	@private

	Counts a transition of the connection into `ready` (`onReady` or `onResumed`) and wakes the playback.
]=]
function Player.Prototype.countSession(self: Player)
	self.readyCount += 1
	self:wake()
end

--[=[
	@within Audio.Player
	@private

	The playback loop. Each step ends on a stop, fails on a closed connection, waits while the connection is not ready,
	waits while a stream source is starved, reads a failed source so its error ends the playback, ends without speaking
	when the source ended or was destroyed before Speaking went out on this session, speaks on a session it has not
	spoken on yet, and otherwise reads one packet and sends it. A source that runs out ends the playback, unless it is
	starved after the read, which means it has no data yet.
]=]
function Player.Prototype.run(self: Player, source: Source): PlaybackEnd
	local connection = self.connection

	while true do
		if self.stopRequested then
			return self:finish("stopped")
		end

		if connection.status == "closed" then
			error(`voice connection closed: {connection.closeDetail}`, 0)
		end

		if connection.status ~= "ready" then
			self:awaitReady()
		elseif source.starved then
			self:awaitData(source)
		elseif source.failure then
			readPacket(source)
		elseif source.ended and self.spokenReadyCount ~= self.readyCount then
			self.logger:debug(`the audio source ended before Speaking went out on this session; ending without it`)

			return self:finish("finished")
		elseif self.spokenReadyCount ~= self.readyCount then
			self:speak()
		else
			local packet = readPacket(source)

			if not packet then
				if source.starved then
					continue
				end

				return self:finish("finished")
			end

			self:sendPacket(packet)
		end
	end
end

--[=[
	@within Audio.Player
	@private

	Waits until the connection is ready or closed, or a stop is requested. Every change that ends the wait wakes the
	playback: `ready` through `onReady` or `onResumed`, a close through `onClosed`, and a stop through `stop`. A wake
	that finds the condition unchanged waits again.
]=]
function Player.Prototype.awaitReady(self: Player)
	local connection = self.connection

	self.logger:debug(`waiting for the voice connection ({connection.status})`)

	while not self.stopRequested and connection.status ~= "ready" and connection.status ~= "closed" do
		self.onWake:wait()
	end
end

--[=[
	@within Audio.Player
	@private

	Waits while a stream source is starved. When Speaking went out on this ready session, it first sends the silence
	tail and Speaking 0, and a tail send that fails on a session that stayed ready fails the playback, as at the end.
	It clears the schedule, so the playback resumes on a fresh one, then polls the source every 20 ms until it has
	data, a stop is requested or the connection is no longer ready.
]=]
function Player.Prototype.awaitData(self: Player, source: Source)
	if self:canSendTail() then
		self:raiseTailFailures(self:sendTail())
	end

	self.logger:debug(`the audio stream is buffering; paused`)
	self.startMillis = nil
	self.elapsedSamples = 0

	while source.starved and not self.stopRequested and self.connection.status == "ready" do
		source:poll()
		self.clock.wait(STARVED_POLL_SECONDS)
	end
end

--[=[
	@within Audio.Player
	@private

	Waits up to `mediaWaitSeconds` for DAVE media readiness, at once without DAVE or after a resume. `noted` is the
	session count taken before the wait. A timeout on that same ready session is logged at info and the playback goes
	on: until media is ready, voice sends Opus silence in place of every packet. When the session changed, the
	connection closed or a stop came, the playback does not play on, so the error is logged at debug instead: the next
	step waits for the new session, fails the playback with the close, or ends it on the stop.
]=]
function Player.Prototype.awaitMedia(self: Player, noted: number)
	local connection = self.connection
	local mediaWaitSeconds = self.mediaWaitSeconds

	self.logger:debug(`waiting up to {mediaWaitSeconds}s for DAVE media readiness`)

	local mediaReady = connection:awaitMediaReadyAsync(mediaWaitSeconds):await()

	if mediaReady:isErr() then
		local failure = tostring(mediaReady:unwrapErr())

		if connection.status == "ready" and not self:sessionChanged(noted) and not self.stopRequested then
			self.logger:info(
				`DAVE media was not ready after {mediaWaitSeconds}s ({failure}); playing anyway, as silence until it is`
			)
		else
			self.logger:debug(`the media wait ended on a session change, a close or a stop: {failure}`)
		end
	end
end

--[=[
	@within Audio.Player
	@private

	Speaks on a new session: waits for DAVE media readiness, then sends Speaking with the player's flags and notes the
	session it went out on. A stop, or a session that changed during the wait, sends nothing and leaves the next step
	to decide.
]=]
function Player.Prototype.speak(self: Player)
	local connection = self.connection
	local noted = self.readyCount

	self:awaitMedia(noted)

	if self.stopRequested or self:sessionChanged(noted) then
		self.logger:debug(`not speaking: a stop came or the voice session changed during the media wait`)

		return
	end

	local spoken = connection:setSpeakingAsync(self.speakingFlags):await()

	if spoken:isErr() then
		self:handleSendError(tostring(spoken:unwrapErr()), noted)
	else
		self.spokenReadyCount = noted
	end
end

--[=[
	@within Audio.Player
	@private

	Sends one packet and paces the next by its duration. A packet that is not valid Opus fails the playback; a failed
	send goes to `handleSendError` and is not paced.
]=]
function Player.Prototype.sendPacket(self: Player, packet: buffer)
	local counted, samples = pcall(voice.opusSamples, packet)
	local noted = self.readyCount

	if not counted then
		error(`invalid Opus packet from the audio source: {samples}`, 0)
	end

	self:markStart()

	local sent = self.connection:sendOpusAsync(packet):await()

	if sent:isErr() then
		self:handleSendError(tostring(sent:unwrapErr()), noted)
	else
		self.packetsSent += 1
		self:pace(samples)
	end
end

--[=[
	@within Audio.Player
	@private

	The send-error rule. A send that failed on a closed connection fails the playback with the close. One that failed
	while the connection was not ready, or after it became ready again since `noted`, was lost to a reconnect: it is
	logged at debug and not sent again. Any other failed send fails the playback with the send's own error.
]=]
function Player.Prototype.handleSendError(self: Player, failure: string, noted: number)
	local connection = self.connection

	if connection.status == "closed" then
		error(`voice connection closed: {connection.closeDetail}`, 0)
	end

	if self:sessionChanged(noted) then
		self.logger:debug(`a send was lost to a voice reconnect: {failure}`)
	else
		error(failure, 0)
	end
end

--[=[
	@within Audio.Player
	@private

	Starts the schedule at the clock's time, just before the first paced send of a playback.
]=]
function Player.Prototype.markStart(self: Player)
	if not self.startMillis then
		self.startMillis = self.clock.nowMillis()
	end
end

--[=[
	@within Audio.Player
	@private

	Waits until the absolute deadline of the samples just sent, `startMillis + elapsedSamples / 48` milliseconds, so
	the pace never drifts with the time a send or a wait takes. Up to 100 ms behind, the next sends catch up after a
	zero wait. More than 100 ms behind (a stall, or the late packet after a wait), or further ahead than the packet
	plus 100 ms (the wall clock stepped back), the schedule resets to one packet after now, logged at debug. The wait
	is called even at 0, so the loop always yields.
]=]
function Player.Prototype.pace(self: Player, samples: number)
	local clock = self.clock
	local packetMilliseconds = samples / SAMPLES_PER_MILLISECOND
	local elapsedSamples = self.elapsedSamples + samples
	local deadline = (self.startMillis :: number) + elapsedSamples / SAMPLES_PER_MILLISECOND
	local now = clock.nowMillis()
	local behind = now - deadline > SCHEDULE_SLACK_MILLISECONDS
	local ahead = deadline - now > packetMilliseconds + SCHEDULE_SLACK_MILLISECONDS
	local offset = math.round(math.abs(now - deadline))
	local waitMilliseconds = if behind or ahead then packetMilliseconds else math.max(0, deadline - now)

	if behind or ahead then
		self.logger:debug(`resetting the audio schedule: {offset} ms {if behind then "behind" else "ahead"}`)
		self.startMillis = now
		self.elapsedSamples = samples
	else
		self.elapsedSamples = elapsedSamples
	end

	clock.wait(waitMilliseconds / 1000)
end

--[=[
	@within Audio.Player
	@private

	Whether Speaking went out on the current session and the connection is ready, so a silence tail can follow.
]=]
function Player.Prototype.canSendTail(self: Player): boolean
	return self.connection.status == "ready" and self.spokenReadyCount == self.readyCount
end

--[=[
	@within Audio.Player
	@private

	Whether the session `noted` was taken on has gone away: the connection is not ready, or it became ready again.
]=]
function Player.Prototype.sessionChanged(self: Player, noted: number): boolean
	return self.connection.status ~= "ready" or self.readyCount ~= noted
end

--[=[
	@within Audio.Player
	@private

	Sends one silence frame and paces it. Returns the send's error, or nil when it went out.
]=]
function Player.Prototype.sendSilence(self: Player): string?
	self:markStart()

	local sent = self.connection:sendOpusAsync(SILENCE_FRAME):await()
	local failure = if sent:isErr() then tostring(sent:unwrapErr()) else nil

	if not failure then
		self.silenceFramesSent += 1
		self:pace(SILENCE_FRAME_SAMPLES)
	end

	return failure
end

--[=[
	@within Audio.Player
	@private

	Sends the silence frames, then Speaking 0, and returns every failure. A send that fails because the session went
	away ends the tail, logged at debug.
]=]
function Player.Prototype.sendTail(self: Player): { string }
	local noted = self.readyCount
	local failures = {}

	for _ = 1, self.silenceFrames do
		local failure = self:sendSilence()

		if failure and self:sessionChanged(noted) then
			self.logger:debug(`the silence tail stopped because the voice session went away: {failure}`)

			return failures
		end

		if failure then
			table.insert(failures, failure)
		end
	end

	local spoken = self.connection:setSpeakingAsync(0):await()

	if spoken:isErr() and self:sessionChanged(noted) then
		self.logger:debug(`Speaking 0 was lost because the voice session went away: {spoken:unwrapErr()}`)
	elseif spoken:isErr() then
		table.insert(failures, tostring(spoken:unwrapErr()))
	end

	self.spokenReadyCount = nil

	return failures
end

--[=[
	@within Audio.Player
	@private

	Ends the playback with `reason`: sends the silence tail when Speaking went out on a ready session, and fails with
	the tail's first error when a tail send failed on a session that stayed ready.
]=]
function Player.Prototype.finish(self: Player, reason: PlaybackEnd): PlaybackEnd
	local failures = {}

	self.ending = true

	if self:canSendTail() then
		failures = self:sendTail()
	else
		self.logger:debug(`ending without silence: Speaking did not go out on this session, or it is not ready`)
	end

	self:raiseTailFailures(failures)

	return reason
end

--[=[
	@within Audio.Player
	@private

	Fails the playback with the silence tail's first failure, after logging the others at warn; a tail with no failures
	does nothing.
]=]
function Player.Prototype.raiseTailFailures(self: Player, failures: { string })
	if #failures > 0 then
		for failureIndex = 2, #failures do
			self.logger:warn(`silence tail failed: {failures[failureIndex]}`)
		end

		error(failures[1], 0)
	end
end

--[=[
	@within Audio.Player
	@private

	The best-effort silence tail after an error, when Speaking went out on a ready session; each failure is logged at
	warn. A tail that raises (a clock that raises, say) is logged at warn too, so the playback's original error
	survives.
]=]
function Player.Prototype.tailAfterError(self: Player)
	if not self:canSendTail() then
		self.logger:debug(`no silence after the error: Speaking did not go out on this session, or it is not ready`)

		return
	end

	local sent, failures = pcall(self.sendTail, self)

	if not sent then
		self.logger:warn(`silence tail after an error raised: {failures}`)

		return
	end

	for _, failure in failures :: { string } do
		self.logger:warn(`silence tail after an error failed: {failure}`)
	end
end

--[=[
	@within Audio.Player
	@private

	Logs the start, then runs the loop. On an error that came before the end, sends the best-effort silence tail, then
	raises the error again. The start is logged here rather than in `start`, so a raising log sink still reaches the
	cleanup.
]=]
function Player.Prototype.play(self: Player, source: Source): PlaybackEnd
	self.logger:debug(`playback started`)

	local ran, outcome = pcall(self.run, self, source)

	if not ran then
		if not self.ending then
			self.ending = true
			self:tailAfterError()
		end

		error(outcome, 0)
	end

	return outcome :: PlaybackEnd
end

--[=[
	@within Audio.Player
	@private

	Runs on every exit after the start checks: destroys the source and disconnects the listeners on the connection, each
	under `pcall`, then clears the flags and the connection's entry before it logs anything, so neither a raising
	`destroy` or disconnect nor a raising log sink can leave the player busy or keep a listener connected. Then it logs
	each `destroy` or disconnect failure at warn, so none replaces the playback's result, and the end at debug.
]=]
function Player.Prototype.cleanup(self: Player, source: Source, played: boolean, outcome: any)
	local result = if played then outcome else "failed"
	local failure = if played then "" else `: {outcome}`
	local destroyed, destroyFailure = pcall(function()
		source:destroy()

		return true
	end)
	local disconnectFailures = {}

	for _, disconnect in self.listenerDisconnects do
		local disconnected, disconnectFailure = pcall(function()
			disconnect()

			return true
		end)

		if not disconnected then
			table.insert(disconnectFailures, disconnectFailure)
		end
	end

	self.listenerDisconnects = {}
	self.playing = false
	self.ending = false
	playingPlayers[self.connection] = nil

	for _, disconnectFailure in disconnectFailures do
		self.logger:warn(`disconnecting a voice connection listener failed: {disconnectFailure}`)
	end

	if not destroyed then
		self.logger:warn(`destroying the audio source failed: {destroyFailure}`)
	end

	self.logger:debug(
		`playback {result} after {self.packetsSent} packets and {self.silenceFramesSent} silence frames{failure}`
	)
end

--[=[
	@within Audio.Player

	Plays `source` and resolves Ok with `"finished"` once the source ran out and the silence tail and Speaking 0 went
	out (or could not be sent because the session went away), or with `"stopped"` after `stop` and the same tail. The
	future is lazy: playback starts when it is polled or awaited.

	Fails at once, without claiming the source, when this player is playing, another player plays on the connection,
	the connection was never joined or has closed, or the source was played before. Fails with
	`voice connection closed: <closeDetail>` when the connection closes before the end, with the send's own error when
	a send fails on a session that stayed ready (a send lost to a reconnect is logged at debug and not sent again),
	with `audio source failed: <error>` when the source raises and with
	`invalid Opus packet from the audio source: <error>` for a packet that is not Opus. Every exit after the start
	destroys the source.
]=]
function Player.Prototype.playAsync(self: Player, source: Source)
	return future.Future.new(function()
		self:start(source)

		local played, outcome = pcall(self.play, self, source)

		self:cleanup(source, played, outcome)

		if not played then
			error(outcome, 0)
		end

		return outcome :: any
	end) :: future.FutureLike<string, PlaybackEnd>
end

--[=[
	@within Audio.Player

	Asks the running playback to end. It ends at its next step with the silence tail and Speaking 0 when Speaking went
	out on a ready session, and resolves `"stopped"`: at once from the readiness wait, within about one 20 ms poll from
	a starved stream's wait (whose tail already went out), within one packet from a pace, when a send or a source read
	returns, and when the media wait ends, which in a DAVE channel can take up to `mediaWaitSeconds`. A stream source's
	own `read` never blocks, and killing a `fromProcess` program never waits for it to exit, so a stream whose producer
	waits for bytes, or is blocked writing them, still stops this quickly. Does nothing, logged at debug, when nothing
	plays or the playback is already sending its tail.
]=]
function Player.Prototype.stop(self: Player)
	if not self.playing then
		self.logger:debug(`stop with nothing playing`)

		return
	end

	if self.ending then
		self.logger:debug(`stop during the silence tail; the tail completes`)

		return
	end

	self.stopRequested = true
	self:wake()
end

--[=[
	@within Audio.Player

	Builds a player for `connection`. Raises for a missing connection, `speakingFlags` of 0, and a negative
	`silenceFrames` or `mediaWaitSeconds`.
]=]
function Player.Interface.new(connection: voice.Connection, options: PlayerOptions?): Player
	local settings: PlayerOptions = options or {}
	local speakingFlags = settings.speakingFlags or DEFAULT_SPEAKING_FLAGS
	local silenceFrames = settings.silenceFrames or DEFAULT_SILENCE_FRAMES
	local mediaWaitSeconds = settings.mediaWaitSeconds or DEFAULT_MEDIA_WAIT_SECONDS

	if not connection then
		error(`audio.player.new needs a voice connection`, 2)
	end

	if speakingFlags == 0 then
		error(`speakingFlags must not be 0`, 2)
	end

	if silenceFrames < 0 then
		error(`silenceFrames must not be negative`, 2)
	end

	if mediaWaitSeconds < 0 then
		error(`mediaWaitSeconds must not be negative`, 2)
	end

	return setmetatable(
		{
			connection = connection,
			speakingFlags = speakingFlags,
			silenceFrames = silenceFrames,
			mediaWaitSeconds = mediaWaitSeconds,
			clock = settings.clock or DEFAULT_CLOCK,
			logger = logger.new("AudioPlayer", settings.logLevel or "Info"),
			playing = false,
			ending = false,
			stopRequested = false,
			readyCount = 0,
			elapsedSamples = 0,
			packetsSent = 0,
			silenceFramesSent = 0,
			onWake = emitter.new(),
			listenerDisconnects = {},
		} :: Player,
		{ __index = Player.Prototype }
	)
end

type Source = audioSource.Source

export type PlaybackEnd = "finished" | "stopped"

export type PlayerClock = {
	nowMillis: () -> number,
	wait: (seconds: number) -> number,
}

export type PlayerOptions = {
	speakingFlags: number?,
	silenceFrames: number?,
	mediaWaitSeconds: number?,
	clock: PlayerClock?,
	logLevel: logger.LogLevel?,
}

export type Player = typeof(Player.Prototype) & {
	connection: voice.Connection,
	speakingFlags: number,
	silenceFrames: number,
	mediaWaitSeconds: number,
	clock: PlayerClock,
	logger: logger.Logger,
	playing: boolean,
	ending: boolean,
	stopRequested: boolean,
	readyCount: number,
	spokenReadyCount: number?,
	startMillis: number?,
	elapsedSamples: number,
	packetsSent: number,
	silenceFramesSent: number,
	onWake: emitter.Emitter<()>,
	listenerDisconnects: { () -> () },
}

return Player.Interface
