local Inherit = require("../../Utils/Inherit")

local DiscordEndpoints = require("../../Data/DiscordEndpoints")

local Future = require("../../Vendor/Future")

local DiscordMessage = require("../Objects/DiscordMessage")
local MessageBuilder = require("../Builders/MessageBuilder")

local DiscordTextChannel = require("DiscordTextChannel")
local DiscordVoiceChannel = require("DiscordVoiceChannel")
local DiscordThreadChannel = require("DiscordThreadChannel")
local DiscordInvite = require("DiscordInvite")

--[=[
	@class Objects.DiscordChannel

	The `DiscordChannel` class represents a generic Discord channel and provides various methods to interact with and manage the channel.
]=]
local DiscordChannel = {}

DiscordChannel.Prototype = {}
DiscordChannel.Interface = {}

--[=[
	@prop type string
	@within Objects.DiscordChannel
	@readonly

	The type of the Discord channel. Default is "DiscordChannel".
]=]
DiscordChannel.Prototype.type = "DiscordChannel"

--[=[
	Triggers the typing indicator in the channel.

	@method triggerTypingIndicator
	@within Objects.DiscordChannel
	@return Future
]=]
function DiscordChannel.Prototype.triggerTypingIndicator(self: DiscordChannel)
	return Future.try(function()
		return self.discordClient.discordGateway:postAsync(string.format(DiscordEndpoints.BotTriggerTypingChannel, self.id), { }):await()
	end)
end

--[=[
	Deletes the channel asynchronously.

	@method deleteAsync
	@within Objects.DiscordChannel
	@return Future
]=]
function DiscordChannel.Prototype.deleteAsync(self: DiscordChannel, messageIds: { string })
	return Future.try(function()
		return self.discordClient.discordGateway:deleteAsync(string.format(DiscordEndpoints.BotDeleteChannel, self.id)):await()
	end)
end

--[=[
	Gets messages from the channel asynchronously.

	@method getMessagesAsync
	@param limit number? -- The maximum number of messages to retrieve.
	@within Objects.DiscordChannel
	@return Future
]=]
function DiscordChannel.Prototype.getMessagesAsync(self: DiscordChannel, limit: number?)
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
	@within Objects.DiscordChannel
	@return Future
]=]
function DiscordChannel.Prototype.getMessageAsync(self: DiscordChannel, messageId: string)
	return Future.try(function()
		local messageObject = self.discordClient.discordGateway:getAsync(string.format(DiscordEndpoints.BotGetChannelMessage, self.id, messageId)):await()
		
		return DiscordMessage.new(self.discordClient, messageObject)
	end)
end

--[=[
	Deletes multiple messages from the channel asynchronously.

	@method bulkDeleteMessagesAsync
	@param messageIds {string} -- A list of message IDs to delete.
	@within Objects.DiscordChannel
	@return Future
]=]
function DiscordChannel.Prototype.bulkDeleteMessagesAsync(self: DiscordChannel, messageIds: { string })
	return Future.try(function()
		return self.discordClient.discordGateway:postAsync(string.format(DiscordEndpoints.BotBulkDeleteMessages, self.id), {
			messages = messageIds
		}):await()
	end)
end

--[=[
	Sends a message to the channel asynchronously.

	@method sendMessageAsync
	@param messageBuilder MessageBuilder -- The message builder object.
	@within Objects.DiscordChannel
	@return Future
]=]
function DiscordChannel.Prototype.sendMessageAsync(self: DiscordChannel, messageBuilder: MessageBuilder.MessageBuilder)
	return Future.try(function()
		return self.discordClient.discordGateway:postAsync(
			string.format(DiscordEndpoints.BotCreateMessage, self.id),
			messageBuilder:toJSONObject()
		):await()
	end)
end

--[=[
	Gets the invites for the channel asynchronously.

	@method getInvitesAsync
	@within Objects.DiscordChannel
	@return Future
]=]
function DiscordChannel.Prototype.getInvitesAsync(self: DiscordChannel)
	return Future.try(function()
		local invites = self.discordClient.discordGateway:getAsync(
			string.format(DiscordEndpoints.BotGetInvites, self.id)
		):await()

		for index, inviteData in invites do
			invites[index] = DiscordInvite.new(self.discordClient, inviteData)
		end

		return invites
	end)
end

--[=[
	Creates an invite for the channel asynchronously.

	@method createInviteAsync
	@param maxAge number? -- The maximum age of the invite in seconds.
	@param maxUses number? -- The maximum number of uses for the invite.
	@param temporary boolean? -- Whether the invite grants temporary membership.
	@within Objects.DiscordChannel
	@return Future
]=]
function DiscordChannel.Prototype.createInviteAsync(self: DiscordChannel, maxAge: number?, maxUses: number?, temporary: boolean?)
	return Future.try(function()
		local inviteData = self.discordClient.discordGateway:postAsync(string.format(DiscordEndpoints.BotGetInvites, self.id), {
			max_age = maxAge,
			max_uses = maxUses,
			temporary = temporary
		}):await()

		return DiscordInvite.new(self.discordClient, inviteData)
	end)
end

--[=[
	Sets the position of the channel asynchronously.

	@method setPositionAsync
	@param position number -- The new position of the channel.
	@param parentId string? -- The ID of the new parent category.
	@param syncPermissions boolean? -- Whether to sync permissions with the new parent.
	@within Objects.DiscordChannel
	@return Future
]=]
function DiscordChannel.Prototype.setPositionAsync(self: DiscordChannel, position: number, parentId: string?, syncPermissions: boolean?)
	return Future.try(function()
		return self.discordClient.discordGateway:patchAsync(string.format(DiscordEndpoints.BotModifyGuildChannelPosition, self.id), {
			id = self.id,
			position = position,
			parent_id = parentId,
			lock_permissions = syncPermissions
		}):await()
	end)
end

--[=[
	Creates a new DiscordChannel instance.
	
	@function new
	@param discordClient any -- The Discord client instance.
	@param rawChannelData any -- The raw data for the channel.
	@within Objects.DiscordChannel
	@return DiscordChannel
]=]
function DiscordChannel.Interface.new(discordClient: any, rawChannelData: any): DiscordChannel
	-- https://discord.com/developers/docs/resources/channel#channel-object-channel-types
	-- todo: support other channel types lol

	local baseChannelObject

	if rawChannelData.type == 0 then
		baseChannelObject = DiscordTextChannel.new(discordClient, rawChannelData) :: any
	elseif rawChannelData.type == 2 then
		baseChannelObject = DiscordVoiceChannel.new(discordClient, rawChannelData) :: any
	elseif rawChannelData.type == 11 or rawChannelData.type == 12 then
		baseChannelObject = DiscordThreadChannel.new(discordClient, rawChannelData) :: any
	else
		baseChannelObject = rawChannelData
	end

	return Inherit(DiscordChannel.Prototype, baseChannelObject)
end

export type DiscordChannel = (DiscordTextChannel.DiscordTextChannel | DiscordVoiceChannel.DiscordVoiceChannel) & typeof(DiscordChannel.Prototype)

return DiscordChannel.Interface