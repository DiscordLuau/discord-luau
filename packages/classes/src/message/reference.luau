--[[
	Implementation of the Discord Reference class in Luau

	https://discord.com/developers/docs/resources/message#message-reference-structure
]]

local apiTypes = require("@api-types/apiTypes")
local messageTypes = require("@api-types/message")

local Reference = {}

Reference.Interface = {}
Reference.Prototype = {}

function Reference.Prototype.sync(self: Reference, referenceData: apiTypes.MessageReferenceObject)
	self.type = messageTypes.MessageReferenceType[referenceData.type]

	self.messageId = referenceData.message_id
	self.guildId = referenceData.guild_id
	self.channelId = referenceData.channel_id
	self.failIfNotExists = referenceData.fail_if_not_exists
end

function Reference.Interface.new(referenceData: apiTypes.MessageReferenceObject): Reference
	local self = setmetatable({} :: Reference, { __index = Reference.Prototype })

	self:sync(referenceData)

	return self
end

export type Reference = typeof(Reference.Prototype) & {
	type: messageTypes.MessageReferenceType?,
	messageId: apiTypes.Snowflake?,
	channelId: apiTypes.Snowflake?,
	guildId: apiTypes.Snowflake?,
	failIfNotExists: boolean?,
}

return Reference.Interface
