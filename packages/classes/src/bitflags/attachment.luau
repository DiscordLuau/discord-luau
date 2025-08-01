--[=[
	@class Classes.AttachmentBitflag
	@__index Prototype

	Implementation of the Discord Role Bitflags in Luau

	https://discord.com/developers/docs/resources/message#attachment-object-attachment-flags
]=]

local bit = require("../../luau_packages/bit")

local AttachmentBitflag = {}

AttachmentBitflag.Interface = {}
AttachmentBitflag.Prototype = {}

--[=[
	@prop flag number
	@within Classes.AttachmentBitflag
	The bitfield representing the attachment flags.
]=]

--[=[
	@within Classes.AttachmentBitflag

	This attachment has been edited using the remix feature on mobile
]=]
function AttachmentBitflag.Prototype.isRemix(self: AttachmentBitflag)
	local targetBit = bit.lshift(1, 2)

	return bit.band(self.flag, targetBit) == targetBit
end

--[=[
	@within Classes.AttachmentBitflag
	@private

	Responsible for constructing this class.
]=]
function AttachmentBitflag.Interface.new(flag: number): AttachmentBitflag
	local self = setmetatable(
		{
			--[=[
				@prop flag number
				@within Classes.AttachmentBitflag
				The bitfield representing the attachment flags.
			]=]
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
