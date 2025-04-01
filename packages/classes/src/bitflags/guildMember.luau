--[=[
	@class Classes.GuildMemberBitflag
	@__index Prototype

	Implementation of the Discord Role Bitflags in Luau

	https://discord.com/developers/docs/resources/guild#guild-member-object-guild-member-flags
]=]

local bit = require("../../luau_packages/bit")

local GuildMemberBitflag = {}

GuildMemberBitflag.Interface = {}
GuildMemberBitflag.Prototype = {}

--[=[
	@within Classes.GuildMemberBitflag
	@private

	Member has left and rejoined the guild	
]=]
function GuildMemberBitflag.Prototype.didRejoin(self: GuildMemberBitflag)
	local targetBit = bit.lshift(1, 0)

	return bit.band(self.flag, targetBit) == targetBit
end

--[=[
	@within Classes.GuildMemberBitflag
	@private

	Member has completed onboarding	
]=]
function GuildMemberBitflag.Prototype.completedOnboarding(self: GuildMemberBitflag)
	local targetBit = bit.lshift(1, 1)

	return bit.band(self.flag, targetBit) == targetBit
end

--[=[
	@within Classes.GuildMemberBitflag
	@private

	Member is exempt from guild verification requirements	
]=]
function GuildMemberBitflag.Prototype.bypassesVerification(self: GuildMemberBitflag)
	local targetBit = bit.lshift(1, 2)

	return bit.band(self.flag, targetBit) == targetBit
end

--[=[
	@within Classes.GuildMemberBitflag
	@private

	Member has started onboarding	
]=]
function GuildMemberBitflag.Prototype.startedOnboarding(self: GuildMemberBitflag)
	local targetBit = bit.lshift(1, 3)

	return bit.band(self.flag, targetBit) == targetBit
end

--[=[
	@within Classes.GuildMemberBitflag
	@private

	Responsible for constructing this class.
]=]
function GuildMemberBitflag.Interface.new(flag: number): GuildMemberBitflag
	local self = setmetatable(
		{
			--[=[
				@prop flag number
				@within Classes.GuildMemberBitflag
			]=]
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
