--[=[
	@class Classes.ThreadMember
	@__index Prototype

	Implementation of the Discord ThreadMember class in Luau

	https://discord.com/developers/docs/resources/channel#thread-member-object
]=]

local stdPolyfills = require("../lune_packages/std_polyfills")

local apiTypes = require("../lune_packages/api_types")
local state = require("../lune_packages/state")

local threadMemberBitflag = require("./bitflags/threadMember")
local member = require("./guild/member")

local ThreadMember = {}

ThreadMember.Interface = {}
ThreadMember.Prototype = {}

--[=[
	@within Classes.ThreadMember
	@private

	Responsible for syncing data to this thread member object. This is typically called by the API when this object is
	created or updated.
]=]
function ThreadMember.Prototype.sync(self: ThreadMember, threadMemberData: apiTypes.ThreadMemberObject)
	--[=[
		@prop joinTimestamp DateTime
		@within Classes.ThreadMember
		The timestamp when this user joined the thread.
	]=]
	self.joinTimestamp = stdPolyfills.datetime.fromIsoDate(threadMemberData.join_timestamp)

	--[=[
		@prop flags ThreadMemberBitflag
		@within Classes.ThreadMember
		The flags that indicate various properties and states of this thread member.
	]=]
	self.flags = threadMemberData.flags and threadMemberBitflag.new(threadMemberData.flags)

	--[=[
		@prop member Member?
		@within Classes.ThreadMember
		The guild member object for this user, if they are a member of the guild.
	]=]
	self.member = threadMemberData.member and member.new(self.state, self.guildId, threadMemberData.member)

	--[=[
		@prop id string?
		@within Classes.ThreadMember
		The unique identifier for this thread member.
	]=]
	self.id = threadMemberData.id

	--[=[
		@prop userId string?
		@within Classes.ThreadMember
		The ID of the user who is a member of this thread.
	]=]
	self.userId = threadMemberData.user_id
end

--[=[
	@within Classes.ThreadMember
	@private

	Responsible for constructing this class.
]=]
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
