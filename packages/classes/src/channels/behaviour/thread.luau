--[[
	Thread Behaviour, responsible for implementing the various properties, and methods for a generic thread channels.
]]

local apiTypes = require("../../../lune_packages/api_types")
local future = require("../../../luau_packages/future")
local rest = require("../../../lune_packages/rest")
local state = require("../../../lune_packages/state")

local threadMember = require("../../threadMember")
local threadMetadata = require("../../channels/threadMetadata")

local ThreadBehaviour = {}

ThreadBehaviour.Interface = {}
ThreadBehaviour.Prototype = {}

--[[
	Adds the current user to a thread. Also requires the thread is not archived. 
]]
function ThreadBehaviour.Prototype.joinThreadAsync<T>(self: Channel<T>)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.channel.joinThreadAsync(request, self.id):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return nil
	end) :: future.FutureLike<string, nil>
end

--[[
	Adds another member to a thread. Requires the ability to send messages in the thread. Also requires the thread is not archived. 
]]
function ThreadBehaviour.Prototype.addMemberToThreadAsync<T>(self: Channel<T>, userId: string)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.channel.addThreadMemberAsync(request, self.id, userId):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return nil
	end) :: future.FutureLike<string, nil>
end

--[[
	Removes the current user from a thread.
]]
function ThreadBehaviour.Prototype.leaveThreadAsync<T>(self: Channel<T>)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.channel.leaveThreadAsync(request, self.id):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return nil
	end) :: future.FutureLike<string, nil>
end

--[[
	Removes another member from a thread. Requires the ability to manage threads.
]]
function ThreadBehaviour.Prototype.removeMemberAsync<T>(self: Channel<T>, userId: string)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.channel.removeThreadMemberAsync(request, self.id, userId):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return nil
	end) :: future.FutureLike<string, nil>
end

--[[
	Gets a thread member by their user ID. Can optionally include the member object.
]]
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

--[[
	Lists all members in a thread. Can optionally include member objects and use pagination.
]]
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

function ThreadBehaviour.Interface.inheritProperties(class: any, channelData: apiTypes.ChannelObject)
	class.totalMessageSent = channelData.total_message_sent
	class.member = channelData.member and threadMember.new(class.state, class.guildId, channelData.member)
	class.threadMetadata = channelData.thread_metadata and threadMetadata.new(channelData.thread_metadata)
	class.memberCount = channelData.member_count
	class.messageCount = channelData.message_count
	class.parentId = channelData.parent_id
	class.ownerId = channelData.owner_id
end

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
