--[=[
	@class Classes.ScheduledEvent
	@__index Prototype

	Implementation of the Discord ScheduledEvent class in Luau

	https://discord.com/developers/docs/resources/scheduledevent#scheduledevent-object
]=]

local apiTypes = require("../../lune_packages/api_types")
local stdPolyfills = require("../../lune_packages/std_polyfills")

local user = require("../user")

local ScheduledEvent = {}

ScheduledEvent.Interface = {}
ScheduledEvent.Prototype = {}

--[=[
	@within Classes.ScheduledEvent
	@private

	Responsible for syncing data to this scheduled event object. This is typically called by the API when this object is
	created or updated.
]=]
function ScheduledEvent.Prototype.sync(self: ScheduledEvent, scheduledEventData: apiTypes.GuildScheduledEventObject)
	--[=[
		@prop id string
		@within Classes.ScheduledEvent
		The unique identifier for this scheduled event
	]=]
	self.id = scheduledEventData.id

	--[=[
		@prop guildId string
		@within Classes.ScheduledEvent
		The guild id which the scheduled event belongs to
	]=]
	self.guildId = scheduledEventData.guild_id

	--[=[
		@prop channelId string?
		@within Classes.ScheduledEvent
		The channel id in which the scheduled event will be hosted, or null if scheduled entity type is EXTERNAL
	]=]
	self.channelId = scheduledEventData.channel_id

	--[=[
		@prop creatorId string?
		@within Classes.ScheduledEvent
		The id of the user that created the scheduled event
	]=]
	self.creatorId = scheduledEventData.creator_id

	--[=[
		@prop name string
		@within Classes.ScheduledEvent
		The name of the scheduled event
	]=]
	self.name = scheduledEventData.name

	--[=[
		@prop description string?
		@within Classes.ScheduledEvent
		The description of the scheduled event
	]=]
	self.description = scheduledEventData.description

	--[=[
		@prop scheduledStartTime std_polyfills.DateTime
		@within Classes.ScheduledEvent
		The time the scheduled event will start
	]=]
	self.scheduledStartTime = stdPolyfills.datetime.fromIsoDate(scheduledEventData.scheduled_start_time)

	--[=[
		@prop scheduledEndTime std_polyfills.DateTime?
		@within Classes.ScheduledEvent
		The time the scheduled event will end, if it has a scheduled end time
	]=]
	self.scheduledEndTime = scheduledEventData.scheduled_end_time
		and stdPolyfills.datetime.fromIsoDate(scheduledEventData.scheduled_end_time)

	--[=[
		@prop privacyLevel apiTypes.ScheduledEventPrivacyLevel
		@within Classes.ScheduledEvent
		The privacy level of the scheduled event
	]=]
	self.privacyLevel = apiTypes.guild.ScheduledEventPrivacyLevel[scheduledEventData.privacy_level]

	--[=[
		@prop status apiTypes.SchedledEventStatus
		@within Classes.ScheduledEvent
		The status of the scheduled event
	]=]
	self.status = apiTypes.guild.SchedledEventStatus[scheduledEventData.status + 1]

	--[=[
		@prop entityType apiTypes.SchedledEventEntityType
		@within Classes.ScheduledEvent
		The type of the scheduled event
	]=]
	self.entityType = apiTypes.guild.SchedledEventEntityType[scheduledEventData.entity_type + 1]

	--[=[
		@prop entityId string?
		@within Classes.ScheduledEvent
		The id of an entity associated with the scheduled event
	]=]
	self.entityId = scheduledEventData.entity_id

	--[=[
		@prop location string?
		@within Classes.ScheduledEvent
		Location of the scheduled event
	]=]
	self.location = scheduledEventData.entity_metadata and scheduledEventData.entity_metadata.location

	--[=[
		@prop creator Classes.User?
		@within Classes.ScheduledEvent
		The user that created the scheduled event
	]=]
	self.creator = scheduledEventData.creator and user.new(scheduledEventData.creator)

	--[=[
		@prop userCount number?
		@within Classes.ScheduledEvent
		The number of users subscribed to the scheduled event
	]=]
	self.userCount = scheduledEventData.user_count

	--[=[
		@prop image string?
		@within Classes.ScheduledEvent
		The cover image hash of the scheduled event
	]=]
	self.image = scheduledEventData.image
end

--[=[
	@within Classes.ScheduledEvent
	@private

	Responsible for constructing this class.
]=]
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
