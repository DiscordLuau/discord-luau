--[[
	Implementation of the Discord IneractionMetadata class in Luau

	https://discord.com/developers/docs/resources/message#message-interaction-metadata-object-message-interaction-metadata-structure
]]

local apiTypes = require("../../lune_packages/api_types")

local user = require("../user")

local IneractionMetadata = {}

IneractionMetadata.Interface = {}
IneractionMetadata.Prototype = {}

function IneractionMetadata.Prototype.sync(
	self: IneractionMetadata,
	interactionData: apiTypes.MessageInteractionMetadatObject
)
	local authorizingIntegrationOwners = {}

	for integrationType, owner in ipairs(interactionData.authorizing_integration_owners) do
		-- todo: are these actually numbers or strings?

		if integrationType == 0 then
			authorizingIntegrationOwners.GuildInstall = owner
		elseif integrationType == 1 then
			authorizingIntegrationOwners.UserInstall = owner
		end
	end

	self.type = apiTypes.interaction.InteractionType[interactionData.type]

	self.user = user.new(interactionData.user)

	self.id = interactionData.id
	self.authorizingIntegrationOwners = authorizingIntegrationOwners
	self.originalResponseMessageId = interactionData.original_response_message_id
	self.interactedMessageId = interactionData.interacted_message_id
	self.triggeringInteractionMetadata = interactionData.triggering_interaction_metadata
		and IneractionMetadata.Interface.new(interactionData.triggering_interaction_metadata)
end

function IneractionMetadata.Interface.new(interactionData: apiTypes.MessageInteractionMetadatObject): IneractionMetadata
	local self = setmetatable({} :: IneractionMetadata, { __index = IneractionMetadata.Prototype })

	self:sync(interactionData)

	return self
end

export type IneractionMetadata = typeof(IneractionMetadata.Prototype) & {
	id: apiTypes.Snowflake,
	type: apiTypes.InteractionType,
	user: user.User,
	authorizingIntegrationOwners: {
		[apiTypes.IntegrationTypesConfig]: apiTypes.Snowflake,
	},
	originalResponseMessageId: apiTypes.Snowflake?,
	interactedMessageId: apiTypes.Snowflake?,
	triggeringInteractionMetadata: IneractionMetadata,
}

return IneractionMetadata.Interface
