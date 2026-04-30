--[=[
	@class Classes.Channels.ThreadMemberBitflag
	@__index Prototype

	Implementation of the Discord Thread Member Bitflags in Luau. This class represents various flags that can be set on a thread member in a Discord channel.

	https://discord.com/developers/docs/resources/channel#thread-member-object

	⚠️ Discord currently doesn't provide any flag documentation for this class? Wack.
]=]

--[=[
	@prop flag number
	@within Classes.Channels.ThreadMemberBitflag
	The bitfield representing the thread member flags.
]=]

local ThreadMemberBitflag = {}

ThreadMemberBitflag.Interface = {}
ThreadMemberBitflag.Prototype = {}

--[=[
	@within Classes.Channels.ThreadMemberBitflag
	@private

	Responsible for constructing this class.
]=]
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
