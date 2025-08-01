--[=[
	@class Classes.IneractionMetadata
	@__index Prototype

	Implementation of the Discord IneractionMetadata class in Luau. This class represents metadata about an interaction that occurred with a message.

	https://discord.com/developers/docs/resources/message#message-interaction-metadata-object-message-interaction-metadata-structure
]=]

local apiTypes = require("../../lune_packages/api_types")

local user = require("../user")

local IneractionMetadata = {}

IneractionMetadata.Interface = {}
IneractionMetadata.Prototype = {}

--[=[
	@within Classes.IneractionMetadata
	@private

	Responsible for syncing data to this interaction metadata object. This is typically called by the API when this object is
	created or updated.
]=]
function IneractionMetadata.Prototype.sync(
	self: IneractionMetadata,
	interactionData: apiTypes.MessageInteractionMetadatObject
)
	--[=[
		@prop type apiTypes.InteractionType
		@within Classes.IneractionMetadata
		The type of interaction that occurred with the message.
	]=]
	self.type = apiTypes.interaction.InteractionType[interactionData.type]

	--[=[
		@prop user Classes.User
		@within Classes.IneractionMetadata
		The user who triggered the interaction.
	]=]
	self.user = user.new(interactionData.user)

	--[=[
		@prop id apiTypes.Snowflake
		@within Classes.IneractionMetadata
		The unique identifier for the interaction.
	]=]
	self.id = interactionData.id

	--[=[
		@prop authorizingIntegrationOwners { [apiTypes.IntegrationTypesConfig]: apiTypes.Snowflake }
		@within Classes.IneractionMetadata
		The mapping of integration types to their respective owners.
	]=]
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

	--[=[
		@prop originalResponseMessageId apiTypes.Snowflake?
		@within Classes.IneractionMetadata
		The ID of the original response message for this interaction.
	]=]
	self.originalResponseMessageId = interactionData.original_response_message_id

	--[=[
		@prop interactedMessageId apiTypes.Snowflake?
		@within Classes.IneractionMetadata
		The ID of the message that was interacted with.
	]=]
	self.interactedMessageId = interactionData.interacted_message_id

	--[=[
		@prop triggeringInteractionMetadata Classes.IneractionMetadata
		@within Classes.IneractionMetadata
		The metadata of the interaction that triggered this interaction.
	]=]
	self.triggeringInteractionMetadata = interactionData.triggering_interaction_metadata
		and IneractionMetadata.Interface.new(interactionData.triggering_interaction_metadata)
end

--[=[
	@within Classes.IneractionMetadata
	@private

	Responsible for constructing this class.
]=]
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
