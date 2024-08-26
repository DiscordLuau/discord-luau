--[[
	Implementation of the Discord ThreadMember class in Luau

	https://discord.com/developers/docs/resources/channel#thread-member-object
]]

local datetime = require("@std-polyfills/datetime")

local apiTypes = require("@api-types/apiTypes")

local threadMemberBitflag = require("@classes/bitflags/threadMember")

local member = require("@classes/guild/member")

local ThreadMember = {}

ThreadMember.Interface = {}
ThreadMember.Prototype = {}

function ThreadMember.Prototype.sync(self: ThreadMember, threadMemberData: apiTypes.ThreadMemberObject)
	self.joinTimestamp = datetime.fromIsoDate(threadMemberData.join_timestamp)

	self.flags = threadMemberData.flags and threadMemberBitflag.new(threadMemberData.flags)
	self.member = threadMemberData.member and member.new(threadMemberData.member)

	self.id = threadMemberData.id
	self.userId = threadMemberData.user_id
end

function ThreadMember.Interface.new(threadMemberData: apiTypes.ThreadMemberObject): ThreadMember
	local self = setmetatable({} :: ThreadMember, { __index = ThreadMember.Prototype })

	self:sync(threadMemberData)

	return self
end

export type ThreadMember = typeof(ThreadMember.Prototype) & {
	id: apiTypes.Snowflake?,
	userId: apiTypes.Snowflake?,
	joinTimestamp: datetime.DateTime,
	flags: threadMemberBitflag.ThreadMemberBitflag,
	member: member.Member?,
}

return ThreadMember.Interface
