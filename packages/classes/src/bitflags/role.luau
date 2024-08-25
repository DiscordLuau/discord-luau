--[[
	Implementation of the Discord Role Bitflags in Luau

	https://discord.com/developers/docs/topics/permissions#role-object-role-flags
]]

local RoleBitflag = {}

RoleBitflag.Interface = {}
RoleBitflag.Prototype = {}

--[[
	Checks if the role is in an onboarding prompt.
]]
function RoleBitflag.Prototype.isInOnboardingPrompt(self: RoleBitflag)
	local bit = bit32.lshift(1, 0)

	return bit32.band(self.flag, bit) == bit
end

function RoleBitflag.Interface.new(flag: number): RoleBitflag
	local self = setmetatable(
		{
			flag = flag,
		} :: RoleBitflag,
		{ __index = RoleBitflag.Prototype }
	)

	return self
end

export type RoleBitflag = typeof(RoleBitflag.Prototype) & {
	flag: number,
}

return RoleBitflag.Interface
