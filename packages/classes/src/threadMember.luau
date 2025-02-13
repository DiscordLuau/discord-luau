--[[
	Implementation of the Discord ThreadMember class in Luau

	https://discord.com/developers/docs/resources/channel#thread-member-object
]]

local stdPolyfills = require("../lune_packages/std_polyfills")

local apiTypes = require("../lune_packages/api_types")
local state = require("../lune_packages/state")

local threadMemberBitflag = require("./bitflags/threadMember")
local member = require("./guild/member")

local ThreadMember = {}

ThreadMember.Interface = {}
ThreadMember.Prototype = {}

function ThreadMember.Prototype.sync(self: ThreadMember, threadMemberData: apiTypes.ThreadMemberObject)
	self.joinTimestamp = stdPolyfills.datetime.fromIsoDate(threadMemberData.join_timestamp)

	self.flags = threadMemberData.flags and threadMemberBitflag.new(threadMemberData.flags)
	self.member = threadMemberData.member and member.new(self.state, self.guildId, threadMemberData.member)

	self.id = threadMemberData.id
	self.userId = threadMemberData.user_id
end

function ThreadMember.Interface.new(
	state: state.State,
	guildId: apiTypes.Snowflake,
	threadMemberData: apiTypes.ThreadMemberObject
): ThreadMember
	local self = setmetatable(
		{
			state = state,
			guildId = guildId,
		} :: ThreadMember,
		{ __index = ThreadMember.Prototype }
	)

	self:sync(threadMemberData)

	return self
end

export type ThreadMember = typeof(ThreadMember.Prototype) & {
	state: state.State,
	guildId: apiTypes.Snowflake,

	id: apiTypes.Snowflake?,
	userId: apiTypes.Snowflake?,
	joinTimestamp: stdPolyfills.DateTime,
	flags: threadMemberBitflag.ThreadMemberBitflag,
	member: member.Member?,
}

return ThreadMember.Interface
