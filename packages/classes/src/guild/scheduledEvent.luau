--[[
	Implementation of the Discord ScheduledEvent class in Luau

	https://discord.com/developers/docs/resources/scheduledevent#scheduledevent-object
]]

local datetime = require("@std-polyfills/datetime")

local apiTypes = require("@api-types/apiTypes")
local guildTypes = require("@api-types/guild")

local user = require("@classes/user")

local ScheduledEvent = {}

ScheduledEvent.Interface = {}
ScheduledEvent.Prototype = {}

function ScheduledEvent.Prototype.sync(self: ScheduledEvent, scheduledeventData: apiTypes.GuildScheduledEventObject)
	self.id = scheduledeventData.id
	self.guildId = scheduledeventData.guild_id
	self.channelId = scheduledeventData.channel_id
	self.creatorId = scheduledeventData.creator_id
	self.name = scheduledeventData.name
	self.description = scheduledeventData.description
	self.scheduledStartTime = datetime.fromIsoDate(scheduledeventData.scheduled_start_time)
	self.scheduledEndTime = scheduledeventData.scheduled_end_time
		and datetime.fromIsoDate(scheduledeventData.scheduled_end_time)
	self.privacyLevel = guildTypes.ScheduledEventPrivacyLevel[scheduledeventData.privacy_level]
	self.status = guildTypes.SchedledEventStatus[scheduledeventData.status + 1]
	self.entityType = guildTypes.SchedledEventEntityType[scheduledeventData.entity_type + 1]
	self.entityId = scheduledeventData.entity_id
	self.location = scheduledeventData.entity_metadata and scheduledeventData.entity_metadata.location
	self.creator = scheduledeventData.creator and user.new(scheduledeventData.creator)
	self.userCount = scheduledeventData.user_count
	self.image = scheduledeventData.image
end

function ScheduledEvent.Interface.new(scheduledeventData: apiTypes.GuildScheduledEventObject): ScheduledEvent
	local self = setmetatable({} :: ScheduledEvent, { __index = ScheduledEvent.Prototype })

	self:sync(scheduledeventData)

	return self
end

export type ScheduledEvent = typeof(ScheduledEvent.Prototype) & {
	id: apiTypes.Snowflake,
	guildId: apiTypes.Snowflake,
	channelId: apiTypes.Snowflake?,
	creatorId: apiTypes.Snowflake?,
	name: string,
	description: string?,
	scheduledStartTime: datetime.DateTime,
	scheduledEndTime: datetime.DateTime?,
	privacyLevel: guildTypes.ScheduledEventPrivacyLevel,
	status: guildTypes.SchedledEventStatus,
	entityType: guildTypes.SchedledEventEntityType,
	entityId: apiTypes.Snowflake?,
	location: string?,
	creator: user.User?,
	userCount: number?,
	image: string?,

	-- todo: what is this?
	-- recurrence_rule
}

return ScheduledEvent.Interface
