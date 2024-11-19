--[[
	Thread Behaviour, responsible for implementing the various properties, and methods for a generic thread channels.
]]

local apiTypes = require("@api-types/apiTypes")

local threadMember = require("@classes/threadMember")
local threadMetadata = require("@classes/channels/threadMetadata")

local ThreadBehaviour = {}

ThreadBehaviour.Interface = {}
ThreadBehaviour.Prototype = {}

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
