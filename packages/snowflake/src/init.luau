--[=[
	@class Snowflake
	@__index Prototype

	Wrapper around Discord snowflakes, allowing developers to query information about a snowflake
]=]

local stdPolyfills = require("./luau_packages/std_polyfills")

local DISCORD_EPOCH = 1420070400000

local Snowflake = {}

Snowflake.Interface = {}
Snowflake.Prototype = {}

local function intoHighLowBits(snowflakeString: string): (number, number)
	local highBits = 0
	local lowBits = 0

	for index = 1, #snowflakeString do
		local digit = string.byte(snowflakeString, index) - 48

		local newLowBits = lowBits * 10 + digit

		highBits = highBits * 10 + math.floor(newLowBits / 4294967296)
		lowBits = newLowBits % 4294967296
	end

	return highBits, lowBits
end

--[=[
	@within Snowflake

	Returns the timestamp of the snowflake
]=]
function Snowflake.Prototype.getTimestamp(self: Snowflake)
	local highBits, lowBits = intoHighLowBits(self.snowflake)

	local timestampMilliseconds = highBits * 1024 + math.floor(lowBits / 4194304)
	local unixTimestampMilliseconds = timestampMilliseconds + DISCORD_EPOCH
	local unixTimestamp = unixTimestampMilliseconds / 1000

	return {
		unixTimestamp = unixTimestamp,
		unixTimestampMillis = unixTimestampMilliseconds,
		toUnixTimestamp = function(_self: any)
			return unixTimestamp
		end,
		toIsoDate = function(_self: any)
			return stdPolyfills.datetime.fromUnixTimestamp(unixTimestamp):toIsoDate()
		end,
	}
end

--[=[
	@within Snowflake

	Returns the internal worker ID of the snowflake
]=]
function Snowflake.Prototype.getInternalWorkerId(self: Snowflake)
	local _, lowBits = intoHighLowBits(self.snowflake)

	local workerIdBits = bit32.rshift(lowBits, 17)
	local workerId = bit32.band(workerIdBits, 0x1F)

	return workerId
end

--[=[
	@within Snowflake

	Returns the internal process ID of the snowflake
]=]
function Snowflake.Prototype.getInternalProcessId(self: Snowflake)
	local _, lowBits = intoHighLowBits(self.snowflake)

	local processIdBits = bit32.rshift(lowBits, 12)
	local processId = bit32.band(processIdBits, 0x1F)

	return processId
end

--[=[
	@within Snowflake

	Returns the increment of the snowflake
]=]
function Snowflake.Prototype.getIncrement(self: Snowflake)
	local _, lowBits = intoHighLowBits(self.snowflake)

	local increment = bit32.band(lowBits, 0xFFF)

	return increment
end

--[=[
	@within Snowflake

	Creates a new snowflake
]=]
function Snowflake.Interface.new(snowflake: string)
	return setmetatable(
		{
			snowflake = snowflake,
		} :: Snowflake,
		{ __index = Snowflake.Prototype }
	)
end

export type Snowflake = typeof(Snowflake.Prototype) & {
	snowflake: string,
}

return Snowflake.Interface
