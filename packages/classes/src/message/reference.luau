--[=[
	@class Classes.Reference
	@__index Prototype

	Implementation of the Discord Reference class in Luau

	https://discord.com/developers/docs/resources/message#message-reference-structure
]=]

local apiTypes = require("../../lune_packages/api_types")

local Reference = {}

Reference.Interface = {}
Reference.Prototype = {}

--[=[
	@within Classes.Reference
	@private

	Responsible for syncing data to this reference object. This is typically called by the API when this object is
	created or updated.
]=]
function Reference.Prototype.sync(self: Reference, referenceData: apiTypes.MessageReferenceObject)
	--[=[
		@prop type apiTypes.MessageReferenceType?
		@within Classes.Reference
		The type of message reference.
	]=]
	self.type = apiTypes.message.MessageReferenceType[referenceData.type]

	--[=[
		@prop messageId apiTypes.Snowflake?
		@within Classes.Reference
		The ID of the referenced message.
	]=]
	self.messageId = referenceData.message_id

	--[=[
		@prop guildId apiTypes.Snowflake?
		@within Classes.Reference
		The ID of the guild containing the referenced message.
	]=]
	self.guildId = referenceData.guild_id

	--[=[
		@prop channelId apiTypes.Snowflake?
		@within Classes.Reference
		The ID of the channel containing the referenced message.
	]=]
	self.channelId = referenceData.channel_id

	--[=[
		@prop failIfNotExists boolean?
		@within Classes.Reference
		Whether to fail if the referenced message does not exist.
	]=]
	self.failIfNotExists = referenceData.fail_if_not_exists
end

--[=[
	@within Classes.Reference
	@private

	Responsible for constructing this class.
]=]
function Reference.Interface.new(referenceData: apiTypes.MessageReferenceObject): Reference
	local self = setmetatable({} :: Reference, { __index = Reference.Prototype })

	self:sync(referenceData)

	return self
end

export type Reference = typeof(Reference.Prototype) & {
	type: apiTypes.MessageReferenceType?,
	messageId: apiTypes.Snowflake?,
	channelId: apiTypes.Snowflake?,
	guildId: apiTypes.Snowflake?,
	failIfNotExists: boolean?,
}

return Reference.Interface
