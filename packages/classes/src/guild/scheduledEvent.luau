--[[
	Implementation of the Discord ScheduledEvent class in Luau

	https://discord.com/developers/docs/resources/scheduledevent#scheduledevent-object
]]

local apiTypes = require("../../lune_packages/api_types")
local stdPolyfills = require("../../lune_packages/std_polyfills")

local user = require("../user")

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
	self.scheduledStartTime = stdPolyfills.datetime.fromIsoDate(scheduledeventData.scheduled_start_time)
	self.scheduledEndTime = scheduledeventData.scheduled_end_time
		and stdPolyfills.datetime.fromIsoDate(scheduledeventData.scheduled_end_time)
	self.privacyLevel = apiTypes.guild.ScheduledEventPrivacyLevel[scheduledeventData.privacy_level]
	self.status = apiTypes.guild.SchedledEventStatus[scheduledeventData.status + 1]
	self.entityType = apiTypes.guild.SchedledEventEntityType[scheduledeventData.entity_type + 1]
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
	scheduledStartTime: stdPolyfills.DateTime,
	scheduledEndTime: stdPolyfills.DateTime?,
	privacyLevel: apiTypes.ScheduledEventPrivacyLevel,
	status: apiTypes.SchedledEventStatus,
	entityType: apiTypes.SchedledEventEntityType,
	entityId: apiTypes.Snowflake?,
	location: string?,
	creator: user.User?,
	userCount: number?,
	image: string?,

	-- todo: what is this?
	-- recurrence_rule
}

return ScheduledEvent.Interface
