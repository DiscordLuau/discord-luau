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

function ScheduledEvent.Prototype.sync(self: ScheduledEvent, scheduledEventData: apiTypes.GuildScheduledEventObject)
	self.id = scheduledEventData.id
	self.guildId = scheduledEventData.guild_id
	self.channelId = scheduledEventData.channel_id
	self.creatorId = scheduledEventData.creator_id
	self.name = scheduledEventData.name
	self.description = scheduledEventData.description
	self.scheduledStartTime = stdPolyfills.datetime.fromIsoDate(scheduledEventData.scheduled_start_time)
	self.scheduledEndTime = scheduledEventData.scheduled_end_time
		and stdPolyfills.datetime.fromIsoDate(scheduledEventData.scheduled_end_time)
	self.privacyLevel = apiTypes.guild.ScheduledEventPrivacyLevel[scheduledEventData.privacy_level]
	self.status = apiTypes.guild.SchedledEventStatus[scheduledEventData.status + 1]
	self.entityType = apiTypes.guild.SchedledEventEntityType[scheduledEventData.entity_type + 1]
	self.entityId = scheduledEventData.entity_id
	self.location = scheduledEventData.entity_metadata and scheduledEventData.entity_metadata.location
	self.creator = scheduledEventData.creator and user.new(scheduledEventData.creator)
	self.userCount = scheduledEventData.user_count
	self.image = scheduledEventData.image
end

function ScheduledEvent.Interface.new(scheduledEventData: apiTypes.GuildScheduledEventObject): ScheduledEvent
	local self = setmetatable({} :: ScheduledEvent, { __index = ScheduledEvent.Prototype })

	self:sync(scheduledEventData)

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
