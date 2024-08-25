--[[
	Implementation of the Discord Role Bitflags in Luau

	https://discord.com/developers/docs/resources/channel#channel-object-channel-flags
]]

local ChannelBitflag = {}

ChannelBitflag.Interface = {}
ChannelBitflag.Prototype = {}

--[[
	if this thread is pinned to the top of its parent GUILD_FORUM or GUILD_MEDIA channel
]]
function ChannelBitflag.Prototype.isPinned(self: ChannelBitflag)
	local bit = bit32.lshift(1, 1)

	return bit32.band(self.flag, bit) == bit
end

--[[
	whether a tag is required to be specified when creating a thread in a
	GUILD_FORUM or a GUILD_MEDIA channel. Tags are specified in the applied_tags field.
]]
function ChannelBitflag.Prototype.requiresTag(self: ChannelBitflag)
	local bit = bit32.lshift(1, 4)

	return bit32.band(self.flag, bit) == bit
end

--[[
	When set hides the embedded media download options. Available only for media channels
]]
function ChannelBitflag.Prototype.hideMediaDownloadOptions(self: ChannelBitflag)
	local bit = bit32.lshift(1, 15)

	return bit32.band(self.flag, bit) == bit
end

function ChannelBitflag.Interface.new(flag: number): ChannelBitflag
	local self = setmetatable(
		{
			flag = flag,
		} :: ChannelBitflag,
		{ __index = ChannelBitflag.Prototype }
	)

	return self
end

export type ChannelBitflag = typeof(ChannelBitflag.Prototype) & {
	flag: number,
}

return ChannelBitflag.Interface
