--[[
	Implementation of the Discord Role Bitflags in Luau

	https://discord.com/developers/docs/resources/channel#thread-member-object

	⚠️ Discord currently doesn't provide any flag documentation for this class? Wack.
]]

local ThreadMemberBitflag = {}

ThreadMemberBitflag.Interface = {}
ThreadMemberBitflag.Prototype = {}

function ThreadMemberBitflag.Interface.new(flag: number): ThreadMemberBitflag
	local self = setmetatable(
		{
			flag = flag,
		} :: ThreadMemberBitflag,
		{ __index = ThreadMemberBitflag.Prototype }
	)

	return self
end

export type ThreadMemberBitflag = typeof(ThreadMemberBitflag.Prototype) & {
	flag: number,
}

return ThreadMemberBitflag.Interface
