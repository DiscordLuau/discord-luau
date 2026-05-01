--[=[
	@class Classes.Guild.StageInstance
	@__index Prototype

	Implementation of the Discord StageInstance class in Luau

	https://discord.com/developers/docs/resources/stage-instance#stage-instance-object
]=]

--[=[
	@prop id string
	@within Classes.Guild.StageInstance
	The id of this Stage instance
]=]

--[=[
	@prop guildId string
	@within Classes.Guild.StageInstance
	The guild id of the associated Stage channel
]=]

--[=[
	@prop channelId string
	@within Classes.Guild.StageInstance
	The id of the associated Stage channel
]=]

--[=[
	@prop topic string
	@within Classes.Guild.StageInstance
	The topic of the Stage instance (1-120 characters)
]=]

--[=[
	@prop privacyLevel apiTypes.PrivacyLevel
	@within Classes.Guild.StageInstance
	The privacy level of the Stage instance
]=]

--[=[
	@prop discoverableDisabled boolean
	@within Classes.Guild.StageInstance
	Whether or not Stage Discovery is disabled (deprecated)
]=]

--[=[
	@prop guildScheduledEventId string?
	@within Classes.Guild.StageInstance
	The id of the scheduled event for this Stage instance
]=]

local apiTypes = require("../../luau_packages/api_types")

local StageInstance = {}

StageInstance.Interface = {}
StageInstance.Prototype = {}

--[=[
	@within Classes.Guild.StageInstance
	@private

	Responsible for syncing data to this stage instance object. This is typically called by the API when this object is
	created or updated.
]=]
function StageInstance.Prototype.sync(self: StageInstance, stageData: apiTypes.StageInstanceObject)
	self.id = stageData.id

	self.guildId = stageData.guild_id

	self.channelId = stageData.channel_id

	self.topic = stageData.topic

	self.privacyLevel = stageData.privacy_level

	self.discoverableDisabled = stageData.discoverable_disabled

	self.guildScheduledEventId = stageData.guild_scheduled_event_id
end

--[=[
	@within Classes.Guild.StageInstance
	@private

	Responsible for constructing this class.
]=]
function StageInstance.Interface.new(stageData: apiTypes.StageInstanceObject): StageInstance
	local self = setmetatable({} :: StageInstance, { __index = StageInstance.Prototype })

	self:sync(stageData)

	return self
end

export type StageInstance = typeof(StageInstance.Prototype) & {
	id: apiTypes.Snowflake,
	guildId: apiTypes.Snowflake,
	channelId: apiTypes.Snowflake,
	topic: string,
	privacyLevel: apiTypes.PrivacyLevel,
	discoverableDisabled: boolean,
	guildScheduledEventId: apiTypes.Snowflake?,
}

return StageInstance.Interface
