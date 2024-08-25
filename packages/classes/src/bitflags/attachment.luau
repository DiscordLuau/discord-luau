--[[
	Implementation of the Discord Role Bitflags in Luau

	https://discord.com/developers/docs/resources/message#attachment-object-attachment-flags
]]

local AttachmentBitflag = {}

AttachmentBitflag.Interface = {}
AttachmentBitflag.Prototype = {}

--[[
	this attachment has been edited using the remix feature on mobile

]]
function AttachmentBitflag.Prototype.isRemix(self: AttachmentBitflag)
	local bit = bit32.lshift(1, 2)

	return bit32.band(self.flag, bit) == bit
end

function AttachmentBitflag.Interface.new(flag: number): AttachmentBitflag
	local self = setmetatable(
		{
			flag = flag,
		} :: AttachmentBitflag,
		{ __index = AttachmentBitflag.Prototype }
	)

	return self
end

export type AttachmentBitflag = typeof(AttachmentBitflag.Prototype) & {
	flag: number,
}

return AttachmentBitflag.Interface
