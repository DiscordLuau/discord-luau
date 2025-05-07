--[=[
	@class Builders.Reference
	@__index Prototype

	Implementation of discords Reference object as a Luau builder.	

	https://discord.com/developers/docs/resources/message#message-reference-structure
]=]

local apiTypes = require("../../lune_packages/api_types")

local Reference = {}

Reference.Prototype = {}
Reference.Interface = {}

--[=[
	@within Builders.Reference

	The type of reference.
]=]
function Reference.Prototype.setType(self: Reference, type: apiTypes.MessageReferenceType): Reference
	self.type = type

	return self
end

--[=[
	@within Builders.Reference

	The id of the originating message.
]=]
function Reference.Prototype.setMessageId(self: Reference, messageId: string): Reference
	self.messageId = messageId

	return self
end

--[=[
	@within Builders.Reference

	The id of the originating message's channel.
]=]
function Reference.Prototype.setChannelId(self: Reference, channelId: string): Reference
	self.channelId = channelId

	return self
end

--[=[
	@within Builders.Reference

	The id of the originating message's guild.
]=]
function Reference.Prototype.setGuildId(self: Reference, guildId: string): Reference
	self.guildId = guildId

	return self
end

--[=[
	@within Builders.Reference

	When sending, whether to error if the referenced message doesn't exist instead of sending as a normal (non-reply) message, default true.
]=]
function Reference.Prototype.setFailIfNotExists(self: Reference, failIfNotExists: boolean): Reference
	self.failIfNotExists = failIfNotExists

	return self
end

--[=[
	@within Builders.Reference

	Responsible for building the Reference JSON that can be parsed by the Discord API.
]=]
function Reference.Prototype.build(self: Reference): JSON
	return {
		type = apiTypes.channel.MessageType[self.type],
		message_id = self.messageId,
		channel_id = self.channelId,
		guild_id = self.guildId,
		fail_if_not_exists = self.failIfNotExists,
	}
end

--[=[
	@within Builders.Reference

	Responsible for creating a new Reference.
]=]
function Reference.Interface.new(resource: {
	type: apiTypes.MessageReferenceType?,
	messageId: string?,
	channelId: string?,
	guildId: string?,
	failIfNotExists: boolean?,
}?): Reference
	local self = setmetatable(
		{
			--[=[
				@prop type api_types.MessageReferenceType
				The type of reference.
			]=]

			--[=[
				@prop messageId string
				The id of the originating message.
			]=]

			--[=[
				@prop channelId string
				The id of the originating message's channel.
			]=]

			--[=[
				@prop guildId string
				The id of the originating message's guild.
			]=]

			--[=[
				@prop failIfNotExists boolean
				When sending, whether to error if the referenced message doesn't exist instead of sending as a normal (non-reply) message.
			]=]
		} :: Reference,
		{
			__index = Reference.Prototype,
		}
	)

	if resource then
		if resource.type then
			self:setType(resource.type)
		end

		if resource.messageId then
			self:setMessageId(resource.messageId)
		end

		if resource.channelId then
			self:setChannelId(resource.channelId)
		end

		if resource.guildId then
			self:setGuildId(resource.guildId)
		end

		if resource.failIfNotExists ~= nil then
			self:setFailIfNotExists(resource.failIfNotExists)
		end
	end

	return self
end

export type Reference = typeof(Reference.Prototype) & {
	type: apiTypes.MessageReferenceType?,
	messageId: apiTypes.Snowflake?,
	channelId: apiTypes.Snowflake?,
	guildId: apiTypes.Snowflake?,
	failIfNotExists: boolean?,
}

export type JSON = typeof(Reference.Prototype.build(nil :: any))

return Reference.Interface
