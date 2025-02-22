--[[
	Implementation of the Discord ActionMetadata class in Luau

	https://discord.com/developers/docs/resources/auto-moderation#auto-moderation-action-object-action-metadata
]]

local apiTypes = require("../../../lune_packages/api_types")

local ActionMetadata = {}

ActionMetadata.Interface = {}
ActionMetadata.Prototype = {}

function ActionMetadata.Prototype.sync(
	self: ActionMetadata,
	actionMetadataData: apiTypes.AutmoderationActionMetadataObject
)
	self.channelId = actionMetadataData.channel_id
	self.durationSeconds = actionMetadataData.duration_seconds
	self.customMessage = actionMetadataData.custom_message
end

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
