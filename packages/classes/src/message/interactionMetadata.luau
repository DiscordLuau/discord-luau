--[=[
	@class Classes.Message.InteractionMetadata
	@__index Prototype

	Implementation of the Discord InteractionMetadata class in Luau. This class represents metadata about an interaction that occurred with a message.

	https://discord.com/developers/docs/resources/message#message-interaction-metadata-object-message-interaction-metadata-structure
]=]

--[=[
	@prop type apiTypes.InteractionType
	@within Classes.Message.InteractionMetadata
	The type of interaction that occurred with the message.
]=]

--[=[
	@prop user Classes.User
	@within Classes.Message.InteractionMetadata
	The user who triggered the interaction.
]=]

--[=[
	@prop id apiTypes.Snowflake
	@within Classes.Message.InteractionMetadata
	The unique identifier for the interaction.
]=]

--[=[
	@prop authorizingIntegrationOwners { [apiTypes.IntegrationTypesConfig]: apiTypes.Snowflake }
	@within Classes.Message.InteractionMetadata
	The mapping of integration types to their respective owners.
]=]

--[=[
	@prop originalResponseMessageId apiTypes.Snowflake?
	@within Classes.Message.InteractionMetadata
	The ID of the original response message for this interaction.
]=]

--[=[
	@prop interactedMessageId apiTypes.Snowflake?
	@within Classes.Message.InteractionMetadata
	The ID of the message that was interacted with.
]=]

--[=[
	@prop triggeringInteractionMetadata Classes.Message.InteractionMetadata?
	@within Classes.Message.InteractionMetadata
	The metadata of the interaction that triggered this interaction.
]=]

local apiTypes = require("../../luau_packages/api_types")

local user = require("../user")

local InteractionMetadata = {}

InteractionMetadata.Interface = {}
InteractionMetadata.Prototype = {}

--[=[
	@within Classes.Message.InteractionMetadata

	Responsible for syncing data to this interaction metadata object. This is typically called by the API when this object is
	created or updated.
]=]
function InteractionMetadata.Prototype.sync(
	self: InteractionMetadata,
	interactionData: apiTypes.MessageInteractionMetadataObject
)
	self.type = apiTypes.interaction.InteractionType[interactionData.type]

	self.user = user.new(interactionData.user)

	self.id = interactionData.id

	local authorizingIntegrationOwners = {}

	for integrationType, owner in interactionData.authorizing_integration_owners do
		-- todo: are these actually numbers or strings?

		if integrationType == 0 then
			authorizingIntegrationOwners.GuildInstall = owner
		elseif integrationType == 1 then
			authorizingIntegrationOwners.UserInstall = owner
		end
	end
	self.authorizingIntegrationOwners = authorizingIntegrationOwners

	self.originalResponseMessageId = interactionData.original_response_message_id

	self.interactedMessageId = interactionData.interacted_message_id

	self.triggeringInteractionMetadata = interactionData.triggering_interaction_metadata
		and InteractionMetadata.Interface.new(interactionData.triggering_interaction_metadata)
end

--[=[
	@within Classes.Message.InteractionMetadata

	Responsible for constructing this class.
]=]
function InteractionMetadata.Interface.new(
	interactionData: apiTypes.MessageInteractionMetadataObject
): InteractionMetadata
	local self = setmetatable({} :: InteractionMetadata, { __index = InteractionMetadata.Prototype })

	self:sync(interactionData)

	return self
end

export type InteractionMetadata = typeof(InteractionMetadata.Prototype) & {
	id: apiTypes.Snowflake,
	type: apiTypes.InteractionType,
	user: user.User,
	authorizingIntegrationOwners: {
		[apiTypes.IntegrationTypesConfig]: apiTypes.Snowflake,
	},
	originalResponseMessageId: apiTypes.Snowflake?,
	interactedMessageId: apiTypes.Snowflake?,
	triggeringInteractionMetadata: InteractionMetadata?,
}

return InteractionMetadata.Interface
