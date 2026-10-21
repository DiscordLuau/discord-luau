--[=[
	@class DiscordStub.Clock
	@__index Prototype

	The clock the stub world runs on. `"real"` leaves `std_polyfills` alone; `"virtual"` swaps `task` and `datetime`
	on the shared table so one virtual second takes `VIRTUAL_TIME_SCALE` real seconds.
]=]

--[=[
	@prop mode string
	@within DiscordStub.Clock
	Whether the clock runs at real speed or 100x.
]=]

--[=[
	@prop originalTask any
	@within DiscordStub.Clock
	The `task` table captured before the virtual clock was installed.
]=]

--[=[
	@prop originalDatetime any
	@within DiscordStub.Clock
	The `datetime` table captured before the virtual clock was installed.
]=]

--[=[
	@prop polyfills any
	@within DiscordStub.Clock
	The `std_polyfills` table this clock swaps.
]=]

--[=[
	@prop startClock number
	@within DiscordStub.Clock
	`os.clock()` when the clock was made.
]=]

--[=[
	@prop startUnixTimestampMillis number
	@within DiscordStub.Clock
	The unix timestamp in milliseconds when the clock was made.
]=]

local stdPolyfills = require("../luau_packages/std_polyfills")

local VIRTUAL_TIME_SCALE = 0.01
local WAIT_FOR_POLL_SECONDS = 0.25

local Clock = {}

Clock.Interface = {}
Clock.Prototype = {}

--[=[
	@within DiscordStub.Clock

	Seconds since the clock was made, real or virtual by mode.
]=]
function Clock.Prototype.now(self: Clock): number
	if self.mode == "real" then
		return os.clock() - self.startClock
	end

	return (os.clock() - self.startClock) / VIRTUAL_TIME_SCALE
end

--[=[
	@within DiscordStub.Clock

	Sleeps `seconds` of the clock's time and returns them.
]=]
function Clock.Prototype.wait(self: Clock, seconds: number?): number
	local duration = seconds or 0

	self.originalTask.wait(if self.mode == "real" then duration else duration * VIRTUAL_TIME_SCALE)

	return duration
end

--[=[
	@within DiscordStub.Clock

	Polls `predicate` every quarter second of the clock's time until it returns a truthy value or `seconds` of the
	clock's time pass. Returns whether the predicate turned truthy in time.
]=]
function Clock.Prototype.waitFor(self: Clock, predicate: () -> any, seconds: number): boolean
	local deadline = self:now() + seconds

	while not predicate() do
		if self:now() >= deadline then
			return false
		end

		self:wait(WAIT_FOR_POLL_SECONDS)
	end

	return true
end

--[=[
	@within DiscordStub.Clock

	Swaps `std_polyfills.task` and `std_polyfills.datetime` for this clock. A real clock does nothing.
]=]
function Clock.Prototype.install(self: Clock)
	if self.mode == "real" then
		return
	end

	local polyfills = self.polyfills

	polyfills.task = setmetatable({
		wait = function(seconds: number?): number
			return self:wait(seconds)
		end,
		delay = function(seconds: number, functionOrThread: any, ...: any): thread
			return self.originalTask.delay(seconds * VIRTUAL_TIME_SCALE, functionOrThread, ...)
		end,
	}, { __index = self.originalTask })

	polyfills.datetime = setmetatable({
		now = function()
			local unixTimestampMillis = math.floor(self.startUnixTimestampMillis + self:now() * 1000)
			local dateTime = self.originalDatetime.fromUnixTimestamp(unixTimestampMillis // 1000)

			return {
				unixTimestamp = unixTimestampMillis // 1000,
				unixTimestampMillis = unixTimestampMillis,
				toIsoDate = function(_self)
					return dateTime:toIsoDate()
				end,
			}
		end,
	}, { __index = self.originalDatetime })
end

--[=[
	@within DiscordStub.Clock

	Puts the real `task` and `datetime` back. Safe to call twice.
]=]
function Clock.Prototype.uninstall(self: Clock)
	if self.mode == "real" then
		return
	end

	local polyfills = self.polyfills

	polyfills.task = self.originalTask
	polyfills.datetime = self.originalDatetime
end

--[=[
	@within DiscordStub.Clock

	Makes a clock. `"real"` is the default.
]=]
function Clock.Interface.new(mode: "real" | "virtual"?, polyfills: any?): Clock
	local source = polyfills or stdPolyfills

	return setmetatable(
		{
			mode = mode or "real",
			startClock = os.clock(),
			startUnixTimestampMillis = source.datetime.now().unixTimestampMillis,
			originalTask = source.task,
			originalDatetime = source.datetime,
			polyfills = source,
		} :: Clock,
		{ __index = Clock.Prototype }
	)
end

export type Clock = typeof(Clock.Prototype) & {
	mode: "real" | "virtual",
	startClock: number,
	startUnixTimestampMillis: number,
	originalTask: any,
	originalDatetime: any,
	polyfills: any,
}

return Clock.Interface
