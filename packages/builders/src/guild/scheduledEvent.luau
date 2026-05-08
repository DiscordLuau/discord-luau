--[=[
	@class Builders.GuildScheduledEvent
	@__index Prototype

	Implementation of Discord's Guild Scheduled Event create/modify params as a Luau builder.

	https://discord.com/developers/docs/resources/guild-scheduled-event#create-guild-scheduled-event-json-params
]=]

local apiTypes = require("../../luau_packages/api_types")
local scheduledEventRecurrenceRule = require("./scheduledEventRecurrenceRule")

local GuildScheduledEvent = {}

GuildScheduledEvent.Prototype = {}
GuildScheduledEvent.Interface = {}

function GuildScheduledEvent.Prototype.setChannelId(self: GuildScheduledEvent, channelId: string): GuildScheduledEvent
	self.channelId = channelId
	return self
end

function GuildScheduledEvent.Prototype.setEntityMetadata(
	self: GuildScheduledEvent,
	location: string
): GuildScheduledEvent
	self.entityMetadata = location
	return self
end

function GuildScheduledEvent.Prototype.setName(self: GuildScheduledEvent, name: string): GuildScheduledEvent
	assert(#name >= 1 and #name <= 100, "Name must be between 1 and 100 characters")
	self.name = name
	return self
end

function GuildScheduledEvent.Prototype.setPrivacyLevel(
	self: GuildScheduledEvent,
	privacyLevel: apiTypes.ScheduledEventPrivacyLevel
): GuildScheduledEvent
	assert(apiTypes.guild.ScheduledEventPrivacyLevel[privacyLevel], "Invalid privacy level")
	self.privacyLevel = privacyLevel
	return self
end

function GuildScheduledEvent.Prototype.setScheduledStartTime(
	self: GuildScheduledEvent,
	startTime: string
): GuildScheduledEvent
	self.scheduledStartTime = startTime
	return self
end

function GuildScheduledEvent.Prototype.setScheduledEndTime(
	self: GuildScheduledEvent,
	endTime: string
): GuildScheduledEvent
	self.scheduledEndTime = endTime
	return self
end

function GuildScheduledEvent.Prototype.setDescription(
	self: GuildScheduledEvent,
	description: string
): GuildScheduledEvent
	assert(#description >= 1 and #description <= 1000, "Description must be between 1 and 1000 characters")
	self.description = description
	return self
end

function GuildScheduledEvent.Prototype.setEntityType(
	self: GuildScheduledEvent,
	entityType: apiTypes.ScheduledEventEntityType
): GuildScheduledEvent
	assert(apiTypes.guild.ScheduledEventEntityType[entityType], "Invalid entity type")
	self.entityType = entityType
	return self
end

function GuildScheduledEvent.Prototype.setImage(self: GuildScheduledEvent, imageDataUri: string): GuildScheduledEvent
	self.image = imageDataUri
	return self
end

function GuildScheduledEvent.Prototype.setRecurrenceRule(
	self: GuildScheduledEvent,
	rule: scheduledEventRecurrenceRule.JSON
): GuildScheduledEvent
	self.recurrenceRule = rule
	return self
end

function GuildScheduledEvent.Prototype.build(self: GuildScheduledEvent): JSON
	assert(self.name, "Guild scheduled event is missing a name")
	assert(self.privacyLevel, "Guild scheduled event is missing a privacy level")
	assert(self.scheduledStartTime, "Guild scheduled event is missing a scheduled start time")
	assert(self.entityType, "Guild scheduled event is missing an entity type")

	if self.entityType == "External" then
		assert(self.entityMetadata, "External events must have entity metadata (location)")
		assert(self.scheduledEndTime, "External events must have a scheduled end time")
	else
		assert(self.channelId, "Stage and Voice events must have a channel_id")
	end

	return {
		channel_id = self.channelId,
		entity_metadata = if self.entityMetadata then { location = self.entityMetadata } else nil,
		name = self.name,
		privacy_level = apiTypes.guild.ScheduledEventPrivacyLevel[self.privacyLevel],
		scheduled_start_time = self.scheduledStartTime,
		scheduled_end_time = self.scheduledEndTime,
		description = self.description,
		entity_type = apiTypes.guild.ScheduledEventEntityType[self.entityType],
		image = self.image,
		recurrence_rule = self.recurrenceRule,
	}
end

function GuildScheduledEvent.Interface.new(resource: {
	channelId: string?,
	entityMetadata: string?,
	name: string?,
	privacyLevel: apiTypes.ScheduledEventPrivacyLevel?,
	scheduledStartTime: string?,
	scheduledEndTime: string?,
	description: string?,
	entityType: apiTypes.ScheduledEventEntityType?,
	image: string?,
	recurrenceRule: scheduledEventRecurrenceRule.JSON?,
}?): GuildScheduledEvent
	local self = setmetatable({} :: GuildScheduledEvent, { __index = GuildScheduledEvent.Prototype })

	if resource then
		if resource.channelId then
			self:setChannelId(resource.channelId)
		end
		if resource.entityMetadata then
			self:setEntityMetadata(resource.entityMetadata)
		end
		if resource.name then
			self:setName(resource.name)
		end
		if resource.privacyLevel then
			self:setPrivacyLevel(resource.privacyLevel)
		end
		if resource.scheduledStartTime then
			self:setScheduledStartTime(resource.scheduledStartTime)
		end
		if resource.scheduledEndTime then
			self:setScheduledEndTime(resource.scheduledEndTime)
		end
		if resource.description then
			self:setDescription(resource.description)
		end
		if resource.entityType then
			self:setEntityType(resource.entityType)
		end
		if resource.image then
			self:setImage(resource.image)
		end
		if resource.recurrenceRule then
			self:setRecurrenceRule(resource.recurrenceRule)
		end
	end

	return self
end

export type GuildScheduledEvent = typeof(GuildScheduledEvent.Prototype) & {
	channelId: string?,
	entityMetadata: string?,
	name: string?,
	privacyLevel: apiTypes.ScheduledEventPrivacyLevel?,
	scheduledStartTime: string?,
	scheduledEndTime: string?,
	description: string?,
	entityType: apiTypes.ScheduledEventEntityType?,
	image: string?,
	recurrenceRule: scheduledEventRecurrenceRule.JSON?,
}

export type JSON = typeof(GuildScheduledEvent.Prototype.build(nil :: any))

return GuildScheduledEvent.Interface
