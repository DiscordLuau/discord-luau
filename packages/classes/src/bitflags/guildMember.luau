--[[
	Implementation of the Discord Role Bitflags in Luau

	https://discord.com/developers/docs/resources/channel#channel-object-channel-flags
]]

local GuildMemberBitflag = {}

GuildMemberBitflag.Interface = {}
GuildMemberBitflag.Prototype = {}

--[[
	Member has left and rejoined the guild	
]]
function GuildMemberBitflag.Prototype.didRejoin(self: GuildMemberBitflag)
	return bit32.lshift(self.flag, 0) == 0
end

--[[
	Member has completed onboarding	
]]
function GuildMemberBitflag.Prototype.completedOnboarding(self: GuildMemberBitflag)
	return bit32.lshift(self.flag, 1) == 1
end

--[[
	Member is exempt from guild verification requirements	
]]
function GuildMemberBitflag.Prototype.bypassesVerification(self: GuildMemberBitflag)
	return bit32.lshift(self.flag, 2) == 2
end

--[[
	Member has started onboarding	
]]
function GuildMemberBitflag.Prototype.startedOnboarding(self: GuildMemberBitflag)
	return bit32.lshift(self.flag, 3) == 3
end

function GuildMemberBitflag.Interface.new(flag: number): GuildMemberBitflag
	local self = setmetatable(
		{
			flag = flag,
		} :: GuildMemberBitflag,
		{ __index = GuildMemberBitflag.Prototype }
	)

	return self
end

export type GuildMemberBitflag = typeof(GuildMemberBitflag.Prototype) & {
	flag: number,
}

return GuildMemberBitflag.Interface
