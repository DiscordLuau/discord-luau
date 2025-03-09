--[=[
	@class Snowflake
	@__index Prototype

	Wrapper around Discord snowflakes, allwowing developers to query information about a snowflake
]=]

local stdPolyfills = require("../lune_packages/std_polyfills")

local bit = require("../luau_packages/bit")

local DISCORD_EPOCH = 1420070400000

local Snowflake = {}

Snowflake.Interface = {}
Snowflake.Prototype = {}

--[=[
	@within Snowflake

	Returns the timestamp of the snowflake
]=]
function Snowflake.Prototype.getTimestamp(self: Snowflake)
	local snowflake = tonumber(self.snowflake) :: number
	local timestamp = bit.shift(snowflake, 22) + DISCORD_EPOCH

	return stdPolyfills.datetime.fromUnixTimestamp(timestamp / 1000)
end

--[=[
	@within Snowflake

	Returns the internal worker ID of the snowflake
]=]
function Snowflake.Prototype.getInternalWorkerId(self: Snowflake)
	local snowflake = tonumber(self.snowflake) :: number
	local internalWorkerId = bit.shift(bit.band(snowflake, 0x3E0000), 17)

	return internalWorkerId
end

--[=[
	@within Snowflake

	Returns the internal process ID of the snowflake
]=]
function Snowflake.Prototype.getInternalProcessId(self: Snowflake)
	local snowflake = tonumber(self.snowflake) :: number
	local internalProcessId = bit.shift(bit.band(snowflake, 0x1F0000), 12)

	return internalProcessId
end

--[=[
	@within Snowflake

	Returns the increment of the snowflake
]=]
function Snowflake.Prototype.getIncrement(self: Snowflake)
	local snowflake = tonumber(self.snowflake) :: number
	local internalProcessId = bit.band(snowflake, 0xFFF)

	return internalProcessId
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
