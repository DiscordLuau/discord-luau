local Future = require("@Vendor/Future")

local Construct = require("@Utils/Construct")
local Extend = require("@Utils/Extend")

local Resolvable = require("@Network/Resolvable")

local BaseDiscordGuildChannel = require("@Objects/BaseDiscordGuildChannel")
local DiscordMessage = require("@Objects/DiscordMessage")

local MessageBuilder = require("@Builders/MessageBuilder")

local DiscordEndpoints = require("@Data/DiscordEndpoints")

local ResolvableType = require("@Enums/ResolvableType")

--[=[
	@class Objects.BaseGuildTextChannel

	A base guild text channel, where any/all text channels extend from.

	@tag inherit Objects.BaseDiscordGuildChannel
]=]

--[=[
	@prop lastPinTimestamp string
	@within Objects.BaseGuildTextChannel
]=]

--[=[
	@prop lastMessageId string?
	@within Objects.BaseGuildTextChannel
]=]

local BaseGuildTextChannel = {}

BaseGuildTextChannel.Prototype = {}
BaseGuildTextChannel.Interface = {}

BaseGuildTextChannel.Prototype.type = "BaseGuildTextChannel"

--[=[
	Triggers the typing indicator in the channel.

	@method triggerTypingIndicator
	@within Objects.BaseGuildTextChannel
	@return Vendor.Future
]=]
function BaseGuildTextChannel.Prototype.triggerTypingIndicator(self: BaseGuildTextChannel)
	return Future.try(function()
		return self.discordClient.discordGateway
			:postAsync(string.format(DiscordEndpoints.BotTriggerTypingChannel, self.id))
			:await()
	end)
end

--[=[
	Gets messages from the channel asynchronously.

	@method getMessagesAsync
	@param limit number? -- The maximum number of messages to retrieve.
	@within Objects.BaseGuildTextChannel
	@return Vendor.Future
]=]
function BaseGuildTextChannel.Prototype.getMessagesAsync(self: BaseGuildTextChannel, limit: number?)
	return Future.try(function()
		local url = string.format(DiscordEndpoints.BotGetChannelMessages, self.id)

		if limit then
			url ..= `?limit={limit}`
		end

		local messageObjects = self.discordClient.discordGateway:getAsync(url):await()

		for index, messageObject in messageObjects do
			messageObjects[index] = DiscordMessage.new(self.discordClient, messageObject)
		end

		return messageObjects
	end)
end

--[=[
	Gets a specific message from the channel asynchronously.

	@method getMessageAsync
	@param messageId string -- The ID of the message to retrieve.
	@within Objects.BaseGuildTextChannel
	@return Vendor.Future
]=]
function BaseGuildTextChannel.Prototype.getMessageAsync(self: BaseGuildTextChannel, messageId: string)
	return Future.try(function()
		local messageObject = self.discordClient.discordGateway
			:getAsync(string.format(DiscordEndpoints.BotGetChannelMessage, self.id, messageId))
			:await()

		return DiscordMessage.new(self.discordClient, messageObject)
	end)
end

--[=[
	Deletes multiple messages from the channel asynchronously.

	@method bulkDeleteMessagesAsync
	@param messageIds {string} -- A list of message IDs to delete.
	@within Objects.BaseGuildTextChannel
	@return Vendor.Future
]=]
function BaseGuildTextChannel.Prototype.bulkDeleteMessagesAsync(self: BaseGuildTextChannel, messageIds: { string })
	return Future.try(function()
		return self.discordClient.discordGateway
			:postAsync(
				string.format(DiscordEndpoints.BotBulkDeleteMessages, self.id),
				Resolvable.new(ResolvableType.JSON, {
					messages = messageIds,
				})
			)
			:await()
	end)
end

--[=[
	Sends a message to the channel asynchronously.

	@method sendMessageAsync
	@param messageBuilder MessageBuilder -- The message builder object.
	@within Objects.BaseGuildTextChannel
	@return Vendor.Future
]=]
function BaseGuildTextChannel.Prototype.sendMessageAsync(
	self: BaseGuildTextChannel,
	messageBuilder: MessageBuilder.MessageBuilder
)
	return Future.try(function()
		return self.discordClient.discordGateway
			:postAsync(string.format(DiscordEndpoints.BotCreateMessage, self.id), messageBuilder:toPayloadObject())
			:await()
	end)
end

--[=[
	Retrieves the pinned messages in the text channel asynchronously.
	
	@method getPinnedMessagesAsync
	@within Objects.BaseGuildTextChannel
	@return Vendor.Future<{[number]: DiscordMessage}> -- A future that resolves to an array of pinned messages.
]=]
function BaseGuildTextChannel.Prototype.getPinnedMessagesAsync(self: BaseGuildTextChannel)
	return Future.try(function()
		local messages = self.discordClient.discordGateway
			:getAsync(string.format(DiscordEndpoints.BotGetPinnedMessages, self.id))
			:await()

		for index, messageData in messages do
			messages[index] = DiscordMessage.new(self.discordClient, messageData)
		end

		return messages
	end)
end

function BaseGuildTextChannel.Interface.new(
	discordClient,
	channelData: {
		id: string,
		guildId: string,
	}
)
	local channelObject = Construct({
		discordClient = discordClient,
	}, BaseGuildTextChannel.Prototype)

	for index, value in channelData do
		(channelObject :: {})[index] = value
	end

	return Extend(channelObject, BaseDiscordGuildChannel.new(discordClient, channelData))
end

export type BaseGuildTextChannel =
	BaseDiscordGuildChannel.BaseDiscordGuildChannel
	& typeof(BaseGuildTextChannel.Prototype)
	& {
		lastPinTimestamp: string,
		lastMessageId: string?,
	}

return BaseGuildTextChannel.Interface
