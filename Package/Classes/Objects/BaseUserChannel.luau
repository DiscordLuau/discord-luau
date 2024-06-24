local Future = require("@Vendor/Future")

local Construct = require("@Utils/Construct")
local Extend = require("@Utils/Extend")

local Resolvable = require("@Network/Resolvable")

local BaseDiscordChannel = require("@Objects/BaseDiscordChannel")
local DiscordMessage = require("@Objects/DiscordMessage")
local DiscordUser = require("@Objects/DiscordUser")

local MessageBuilder = require("@Builders/MessageBuilder")

local DiscordEndpoints = require("@Data/DiscordEndpoints")

local ResolvableType = require("@Enums/ResolvableType")

--[=[
	@class Objects.BaseUserChannel

	A base User channel, allwoing bots to interact with channels outside of a discord Guild.

	@tag inherit Objects.BaseDiscordChannel
]=]

--[=[
	@prop id string
	@within Objects.BaseUserChannel
]=]

--[=[
	@prop recipients { Objects.DiscordUser }
	@within Objects.BaseUserChannel
]=]

local BaseUserChannel = {}

BaseUserChannel.Prototype = {}
BaseUserChannel.Interface = {}

BaseUserChannel.Prototype.type = "BaseUserChannel"

--[=[
	Triggers the typing indicator in the channel.

	@method triggerTypingIndicator
	@within Objects.BaseUserChannel
	@return Vendor.Future
]=]
function BaseUserChannel.Prototype.triggerTypingIndicator(self: BaseUserChannel)
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
	@within Objects.BaseUserChannel
	@return Vendor.Future
]=]
function BaseUserChannel.Prototype.getMessagesAsync(self: BaseUserChannel, limit: number?)
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
	@within Objects.BaseUserChannel
	@return Vendor.Future
]=]
function BaseUserChannel.Prototype.getMessageAsync(self: BaseUserChannel, messageId: string)
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
	@within Objects.BaseUserChannel
	@return Vendor.Future
]=]
function BaseUserChannel.Prototype.bulkDeleteMessagesAsync(self: BaseUserChannel, messageIds: { string })
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
	@within Objects.BaseUserChannel
	@return Vendor.Future
]=]
function BaseUserChannel.Prototype.sendMessageAsync(
	self: BaseUserChannel,
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
	@within Objects.BaseUserChannel
	@return Vendor.Future<{[number]: DiscordMessage}> -- A future that resolves to an array of pinned messages.
]=]
function BaseUserChannel.Prototype.getPinnedMessagesAsync(self: BaseUserChannel)
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

function BaseUserChannel.Interface.new(
	discordClient,
	channelData: {
		id: string,

		[string]: any,
	}
)
	local channelObject = Construct({
		discordClient = discordClient,
	}, BaseUserChannel.Prototype)

	if channelData.recipients then
		for key, value in channelData.recipients do
			channelData.recipients[key] = DiscordUser.new(discordClient, value)
		end
	end

	for index, value in channelData do
		(channelObject :: {})[index] = value
	end

	return Extend(channelObject, BaseDiscordChannel.new(discordClient, channelData))
end

export type BaseUserChannel = BaseDiscordChannel.BaseDiscordChannel & typeof(BaseUserChannel.Prototype) & {
	discordClient: any,
	id: string,

	recipients: { DiscordUser.DiscordUser },
}

return BaseUserChannel.Interface
