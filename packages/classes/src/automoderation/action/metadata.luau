--[=[
	@class Classes.AutoModeration.ActionMetadata
	@__index Prototype

	Implementation of the Discord ActionMetadata class in Luau

	https://discord.com/developers/docs/resources/auto-moderation#auto-moderation-action-object-action-metadata
]=]

--[=[
	@prop channelId string
	@within Classes.AutoModeration.ActionMetadata

	The ID of the channel to which content should be logged. This is required when the action type is set to
	SEND_ALERT_MESSAGE.
]=]

--[=[
	@prop durationSeconds number
	@within Classes.AutoModeration.ActionMetadata

	The timeout duration in seconds. This is required when the action type is set to TIMEOUT.
]=]

--[=[
	@prop customMessage string?
	@within Classes.AutoModeration.ActionMetadata

	A custom message that will be displayed to members when their message is blocked. Maximum 150 characters.
]=]

local apiTypes = require("../../../luau_packages/api_types")

local ActionMetadata = {}

ActionMetadata.Interface = {}
ActionMetadata.Prototype = {}

--[=[
	@within Classes.AutoModeration.ActionMetadata
	@private

	Responsible for syncing data to this action metadata object. This is typically called by the API when this object is
	created or updated.
]=]
function ActionMetadata.Prototype.sync(
	self: ActionMetadata,
	actionMetadataData: apiTypes.AutmoderationActionMetadataObject
)
	self.channelId = actionMetadataData.channel_id

	self.durationSeconds = actionMetadataData.duration_seconds

	self.customMessage = actionMetadataData.custom_message
end

--[=[
	@within Classes.AutoModeration.ActionMetadata
	@private

	Responsible for constructing this class.
]=]
function ActionMetadata.Interface.new(actionMetadataData: apiTypes.AutmoderationActionMetadataObject): ActionMetadata
	local self = setmetatable({} :: ActionMetadata, { __index = ActionMetadata.Prototype })

	self:sync(actionMetadataData)

	return self
end

export type ActionMetadata = typeof(ActionMetadata.Prototype) & {
	channelId: apiTypes.Snowflake,
	durationSeconds: number,
	customMessage: string?,
}

return ActionMetadata.Interface
