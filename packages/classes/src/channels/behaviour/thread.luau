--[=[
	@class Classes.ThreadBehaviour
	@__index Prototype

	Behaviour class that implements the properties and methods specific to thread channels in Discord.
	This behaviour is inherited by thread channel classes to provide thread-specific functionality.

	Thread behaviours include:
	- Managing thread members (join, leave, add, remove)
	- Retrieving thread member information
	- Handling thread metadata and statistics
	- Managing thread ownership and parent relationships
]=]

local apiTypes = require("../../../lune_packages/api_types")
local future = require("../../../luau_packages/future")
local rest = require("../../../lune_packages/rest")
local state = require("../../../lune_packages/state")

local threadMember = require("../../threadMember")
local threadMetadata = require("../../channels/threadMetadata")

local ThreadBehaviour = {}

ThreadBehaviour.Interface = {}
ThreadBehaviour.Prototype = {}

--[=[
	@within Classes.ThreadBehaviour
	Adds the current user to a thread. Also requires the thread is not archived.
]=]
function ThreadBehaviour.Prototype.joinAsync<T>(self: Channel<T>)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.channel.joinThreadAsync(request, self.id):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return nil
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Classes.ThreadBehaviour
	Adds another member to a thread. Requires the ability to send messages in the thread. Also requires the thread is not archived.
]=]
function ThreadBehaviour.Prototype.addMemberAsync<T>(self: Channel<T>, userId: string)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.channel.addThreadMemberAsync(request, self.id, userId):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return nil
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Classes.ThreadBehaviour
	Removes the current user from a thread.
]=]
function ThreadBehaviour.Prototype.leaveAsync<T>(self: Channel<T>)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.channel.leaveThreadAsync(request, self.id):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return nil
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Classes.ThreadBehaviour
	Removes another member from a thread. Requires the ability to manage threads.
]=]
function ThreadBehaviour.Prototype.removeMemberAsync<T>(self: Channel<T>, userId: string)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.channel.removeThreadMemberAsync(request, self.id, userId):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return nil
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Classes.ThreadBehaviour
	Gets a thread member by their user ID. Can optionally include the member object.
]=]
function ThreadBehaviour.Prototype.getMemberAsync<T>(self: Channel<T>, userId: string, withMember: boolean?)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.channel
			.getThreadMemberAsync(request, self.id, userId, {
				withMember = withMember,
			})
			:await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return threadMember.new(self.state, self.guildId, response:unwrapOk())
	end) :: future.FutureLike<string, threadMember.ThreadMember>
end

--[=[
	@within Classes.ThreadBehaviour
	Lists all members in a thread. Can optionally include member objects and use pagination.
]=]
function ThreadBehaviour.Prototype.listMembersAsync<T>(
	self: Channel<T>,
	withMember: boolean?,
	after: string?,
	limit: number?
)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.channel
			.listThreadMembersAsync(request, self.id, {
				withMember = withMember,
				after = after,
				limit = limit,
			})
			:await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		local threadMembers = {}

		for _, memberData in response:unwrapOk() do
			table.insert(threadMembers, threadMember.new(self.state, self.guildId, memberData))
		end

		return threadMembers
	end) :: future.FutureLike<string, { threadMember.ThreadMember }>
end

--[=[
	@within Classes.ThreadBehaviour
	@private

	Inherits properties from the channel data into the class instance.
	This is typically called during object creation or updates.
]=]
function ThreadBehaviour.Interface.inheritProperties(class: any, channelData: apiTypes.ChannelObject)
	--[=[
		@within Classes.ThreadBehaviour
		@prop totalMessageSent number
		The total number of messages sent in this thread.
	]=]
	class.totalMessageSent = channelData.total_message_sent

	--[=[
		@within Classes.ThreadBehaviour
		@prop member Classes.ThreadMember?
		The current user's thread member object, if they are a member of this thread.
	]=]
	class.member = channelData.member and threadMember.new(class.state, class.guildId, channelData.member)

	--[=[
		@within Classes.ThreadBehaviour
		@prop threadMetadata Classes.ThreadMetadata?
		Metadata about the thread, including archive status and auto-archive duration.
	]=]
	class.threadMetadata = channelData.thread_metadata and threadMetadata.new(channelData.thread_metadata)

	--[=[
		@within Classes.ThreadBehaviour
		@prop memberCount number
		The number of members in this thread.
	]=]
	class.memberCount = channelData.member_count

	--[=[
		@within Classes.ThreadBehaviour
		@prop messageCount number
		The number of messages in this thread.
	]=]
	class.messageCount = channelData.message_count

	--[=[
		@within Classes.ThreadBehaviour
		@prop parentId string?
		The ID of the parent channel this thread belongs to.
	]=]
	class.parentId = channelData.parent_id

	--[=[
		@within Classes.ThreadBehaviour
		@prop ownerId string
		The ID of the user who created this thread.
	]=]
	class.ownerId = channelData.owner_id
end

--[=[
	@within Classes.ThreadBehaviour
	@private

	Inherits methods from the ThreadBehaviour prototype into the class instance.
	This is typically called during object creation or updates.
]=]
function ThreadBehaviour.Interface.inheritMethods(class: any)
	for key, value in ThreadBehaviour.Prototype do
		class[key] = value
	end
end

type Channel<T> = T & ThreadBehaviour & {
	state: state.State,
	id: string,
	guildId: string,

	sync: (...any) -> (),
}

export type ThreadBehaviourMethods = typeof(ThreadBehaviour.Prototype)
export type ThreadBehaviourProperties = {
	totalMessageSent: number,
	member: threadMember.ThreadMember?,
	threadMetadata: threadMetadata.ThreadMetadata?,
	memberCount: number,
	messageCount: number,
	parentId: string?,
	ownerId: string,
}

export type ThreadBehaviour = ThreadBehaviourMethods & ThreadBehaviourProperties

return ThreadBehaviour.Interface
