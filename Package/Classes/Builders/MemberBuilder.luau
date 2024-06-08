local Datetime = require("@Std/Datetime")

local Enumerate = require("@Utils/Enumerate")
local Construct = require("@Utils/Construct")

local Resolvable = require("@Network/Resolvable")

local ResolvableType = require("@Enums/ResolveableType")

--[=[
	@class Builders.MemberBuilder

	MemberBuilder is used to update a member object for a guild,

	Usage:
	```lua
	local member = MemberBuilder.new()
		:setNickname("Discordian #0!")
	```
]=]
local MemberBuilder = {}

MemberBuilder.Interface = {}
MemberBuilder.Prototype = {}

MemberBuilder.Prototype.type = "MemberBuilder"

--[=[
	Sets the nickname of a discord member
	
	@method setNickname
	@param nickname string
	@within Builders.MemberBuilder
	@return Builders.MemberBuilder
]=]
function MemberBuilder.Prototype.setNickname(self: MemberBuilder, nickname: string)
	self.nickname = nickname

	return self
end

--[=[
	Adds a role to a member
	
	@method addRole
	@param roleId string
	@within Builders.MemberBuilder
	@return Builders.MemberBuilder
]=]
function MemberBuilder.Prototype.addRole(self: MemberBuilder, roleId: string)
	table.insert(self.roles, roleId)

	return self
end

--[=[
	Sets the muted state for this member
	
	@method setMuted
	@param muted boolean
	@within Builders.MemberBuilder
	@return Builders.MemberBuilder
]=]
function MemberBuilder.Prototype.setMuted(self: MemberBuilder, muted: boolean)
	self.mute = muted

	return self
end

--[=[
	Sets the deafened state for this member
	
	@method setDeafened
	@param deafened boolean
	@within Builders.MemberBuilder
	@return Builders.MemberBuilder
]=]
function MemberBuilder.Prototype.setDeafened(self: MemberBuilder, deafened: boolean)
	self.deaf = deafened

	return self
end

--[=[
	Allows you to specify the voice channel to move the member too.
	
	@method setActiveVoiceChannel
	@param voiceChannelId string
	@within Builders.MemberBuilder
	@return Builders.MemberBuilder
]=]
function MemberBuilder.Prototype.setActiveVoiceChannel(self: MemberBuilder, voiceChannelId: string)
	self.channelId = voiceChannelId

	return self
end

--[=[
	Allows you to timeout a members communication.
	
	@method setTimeoutFor
	@param epoch number
	@within Builders.MemberBuilder
	@return Builders.MemberBuilder
]=]
function MemberBuilder.Prototype.setTimeoutFor(self: MemberBuilder, epoch: number)
	self.communicationDisabledUntil = epoch

	return self
end

--[=[
	Sets the bitflags for this Member
	
	@method setFlags
	@param flags number
	@within Builders.MemberBuilder
	@return Builders.MemberBuilder
]=]
function MemberBuilder.Prototype.setFlags(self: MemberBuilder, flags: number)
	self.flags = flags

	return self
end

--[=[
	Converts the member to a JSON object that can be sent to the Discord API.
	
	@method toPayloadObject
	@within Builders.MemberBuilder
	@return Network.Resolvable
]=]
function MemberBuilder.Prototype.toPayloadObject(self: MemberBuilder)
	local communicationDisabledUntil

	if self.communicationDisabledUntil then
		communicationDisabledUntil = Datetime.fromUnixTimestamp(os.time() + self.communicationDisabledUntil):toIsoDate()
	end

	return Resolvable.new(ResolvableType.JSON, {
		nick = self.nickname,
		roles = self.roles,
		mute = self.mute,
		deaf = self.deaf,
		channel_id = self.channelId,
		communication_disabled_until = communicationDisabledUntil,
		flags = self.flags,
	})
end

--[=[
	Creates a new instance of MemberBuilder.
	
	@function new
	@within Builders.MemberBuilder
	@return Builders.MemberBuilder -- A new instance of MemberBuilder.
]=]
function MemberBuilder.Interface.new()
	return (Construct({
		roles = {},
	}, MemberBuilder.Prototype) :: unknown) :: MemberBuilder
end

export type MemberBuilder = typeof(MemberBuilder.Prototype) & {
	nickname: string,
	roles: { string },
	mute: boolean,
	deaf: boolean,
	channelId: string,
	communicationDisabledUntil: number,
	flags: number,
}

return MemberBuilder.Interface
