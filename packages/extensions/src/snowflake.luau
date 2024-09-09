--[[
	Wrapper around Discord snowflakes, allwowing developers to query information about a snowflake
]]

local datetime = require("@std-polyfills/datetime")

local bit = require("@vendor/bit")

local DISCORD_EPOCH = 1420070400000

local Snowflake = {}

Snowflake.Interface = {}
Snowflake.Prototype = {}

--[[
	Returns the timestamp of the snowflake
]]
function Snowflake.Prototype.getTimestamp(self: Snowflake)
	local snowflake = tonumber(self.snowflake) :: number
	local timestamp = bit.shift(snowflake, 22) + DISCORD_EPOCH

	return datetime.fromUnixTimestamp(timestamp / 1000)
end

--[[
	Returns the internal worker ID of the snowflake
]]
function Snowflake.Prototype.getInternalWorkerId(self: Snowflake)
	local snowflake = tonumber(self.snowflake) :: number
	local internalWorkerId = bit.shift(bit.band(snowflake, 0x3E0000), 17)

	return internalWorkerId
end

--[[
	Returns the internal process ID of the snowflake
]]
function Snowflake.Prototype.getInternalProcessId(self: Snowflake)
	local snowflake = tonumber(self.snowflake) :: number
	local internalProcessId = bit.shift(bit.band(snowflake, 0x1F0000), 12)

	return internalProcessId
end

--[[
	Returns the increment of the snowflake
]]
function Snowflake.Prototype.getIncrement(self: Snowflake)
	local snowflake = tonumber(self.snowflake) :: number
	local internalProcessId = bit.band(snowflake, 0xFFF)

	return internalProcessId
end

--[[
	Creates a new snowflake
]]
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
