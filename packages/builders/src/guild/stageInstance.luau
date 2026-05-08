--[=[
	@class Builders.StageInstance
	@__index Prototype

	Implementation of Discord's Create Stage Instance params as a Luau builder.

	https://discord.com/developers/docs/resources/stage-instance#create-stage-instance-json-params
]=]

local apiTypes = require("../../luau_packages/api_types")

local StageInstance = {}

StageInstance.Prototype = {}
StageInstance.Interface = {}

function StageInstance.Prototype.setChannelId(self: StageInstance, channelId: string): StageInstance
	self.channelId = channelId
	return self
end

function StageInstance.Prototype.setTopic(self: StageInstance, topic: string): StageInstance
	assert(#topic >= 1 and #topic <= 120, "Topic must be between 1 and 120 characters")
	self.topic = topic
	return self
end

function StageInstance.Prototype.setPrivacyLevel(
	self: StageInstance,
	privacyLevel: apiTypes.StageInstancePrivacyLevel
): StageInstance
	assert(apiTypes.guild.StageInstancePrivacyLevel[privacyLevel], "Invalid privacy level")
	self.privacyLevel = privacyLevel
	return self
end

function StageInstance.Prototype.setSendStartNotification(
	self: StageInstance,
	sendStartNotification: boolean
): StageInstance
	self.sendStartNotification = sendStartNotification
	return self
end

function StageInstance.Prototype.setGuildScheduledEventId(
	self: StageInstance,
	scheduledEventId: string
): StageInstance
	self.guildScheduledEventId = scheduledEventId
	return self
end

function StageInstance.Prototype.build(self: StageInstance): JSON
	assert(self.channelId, "Stage instance is missing a channel_id")
	assert(self.topic, "Stage instance is missing a topic")

	return {
		channel_id = self.channelId,
		topic = self.topic,
		privacy_level = if self.privacyLevel
			then apiTypes.guild.StageInstancePrivacyLevel[self.privacyLevel]
			else nil,
		send_start_notification = self.sendStartNotification,
		guild_scheduled_event_id = self.guildScheduledEventId,
	}
end

function StageInstance.Interface.new(resource: {
	channelId: string?,
	topic: string?,
	privacyLevel: apiTypes.StageInstancePrivacyLevel?,
	sendStartNotification: boolean?,
	guildScheduledEventId: string?,
}?): StageInstance
	local self = setmetatable({} :: StageInstance, { __index = StageInstance.Prototype })

	if resource then
		if resource.channelId then
			self:setChannelId(resource.channelId)
		end
		if resource.topic then
			self:setTopic(resource.topic)
		end
		if resource.privacyLevel then
			self:setPrivacyLevel(resource.privacyLevel)
		end
		if resource.sendStartNotification ~= nil then
			self:setSendStartNotification(resource.sendStartNotification)
		end
		if resource.guildScheduledEventId then
			self:setGuildScheduledEventId(resource.guildScheduledEventId)
		end
	end

	return self
end

export type StageInstance = typeof(StageInstance.Prototype) & {
	channelId: string?,
	topic: string?,
	privacyLevel: apiTypes.StageInstancePrivacyLevel?,
	sendStartNotification: boolean?,
	guildScheduledEventId: string?,
}

export type JSON = typeof(StageInstance.Prototype.build(nil :: any))

return StageInstance.Interface
