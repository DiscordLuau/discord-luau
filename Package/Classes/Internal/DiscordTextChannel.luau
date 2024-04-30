local Construct = require("../../Utils/Construct")

local CacheType = require("../../Enums/CacheType")
local DiscordEndpoints = require("../../Enums/DiscordEndpoints")

local Future = require("../../Vendor/Future")

local DiscordMessage = require("../Internal/DiscordMessage")
local DiscordMessageType = require("../../Types/DiscordMessage")

--[=[
	@class Internal.DiscordTextChannel

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local DiscordTextChannel = {}

DiscordTextChannel.Prototype = {}
DiscordTextChannel.Interface = {}

DiscordTextChannel.Prototype.type = "DiscordTextChannel"

function DiscordTextChannel.Prototype.getMessagesAsync(self: DiscordTextChannel, limit: number?)
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

function DiscordTextChannel.Prototype.getMessageAsync(self: DiscordTextChannel, messageId: string)
	return Future.try(function()
		local messageObject = self.discordClient.discordGateway:getAsync(string.format(DiscordEndpoints.BotGetChannelMessage, self.id, messageId)):await()
		
		return DiscordMessage.new(self.discordClient, messageObject)
	end)
end

function DiscordTextChannel.Prototype.bulkDeleteMessagesAsync(self: DiscordTextChannel, messageIds: { string })
	return Future.try(function()
		return self.discordClient.discordGateway:postAsync(string.format(DiscordEndpoints.BotBulkDeleteMessages, self.id), {
			messages = messageIds
		}):await()
	end)
end

function DiscordTextChannel.Prototype.sendMessageAsync(self: DiscordTextChannel, messageData: DiscordMessageType.MessageSchema)
	return Future.try(function()
		local components = {}

		if messageData.components then
			for _, component in messageData.components do
				table.insert(components, component:toJSONObject())
			end
		end

		return self.discordClient.discordGateway:postAsync(string.format(DiscordEndpoints.BotCreateMessage, self.id), {
			content = messageData.content or nil,
			nonce = messageData.nonce or nil,
			tts = messageData.tts or false,
			components = components,
			sticker_ids = messageData.stickerIds,
			flags = messageData.flags or nil, --fixme: should use a bitfield.
			enforce_nonce = messageData.enforceNonce or false
		}):await()
	end)
end

function DiscordTextChannel.Prototype.deleteAsync(self: DiscordTextChannel, messageIds: { string })
	return Future.try(function()
		return self.discordClient.discordGateway:deleteAsync(string.format(DiscordEndpoints.BotDeleteChannel, self.id)):await()
	end)
end

function DiscordTextChannel.Prototype.modifyAsync(self: DiscordTextChannel, channelSchema: DiscordTextChannelSchema)
	return Future.try(function()
		return self.discordClient.discordGateway:patchAsync(string.format(DiscordEndpoints.BotModifyChannel, self.id), {
			name = channelSchema.name,
			position = channelSchema.position,
			topic = channelSchema.topic,
			nsfw = channelSchema.nsfw,
			rate_limit_per_user = channelSchema.rateLimitPerUser,
			parent_id = channelSchema.parentId,
			default_auto_archive_duration = channelSchema.defaultAutoArchiveDurection,
			default_thread_rate_limit_per_user = channelSchema.defaultThreadRateLimitPerUser
		}):await()
	end)
end

function DiscordTextChannel.Prototype.triggerTypingIndicatorAsync(self: DiscordTextChannel)
	return Future.try(function()
		return self.discordClient.discordGateway:postAsync(string.format(DiscordEndpoints.BotTriggerTypingChannel, self.id), { }):await()
	end)
end

function DiscordTextChannel.Prototype.getPinnedMessagesAsync(self: DiscordTextChannel)
	return Future.try(function()
		local messages = self.discordClient.discordGateway:getAsync(string.format(DiscordEndpoints.BotGetPinnedMessages, self.id), { }):await()

		for index, messageData in messages do
			messages[index] = DiscordMessage.new(self.discordClient, messageData)
		end

		return messages
	end)
end

function DiscordTextChannel.Interface.new(discordClient: any, channelData: {
	id: string,
	recipients: { unknown },
}): DiscordTextChannel
	local self = discordClient.discordCache:getDataOr(CacheType.DiscordTextChannel, channelData.id, function()
		return Construct({
			id = channelData.id,
	
			discordClient = discordClient
		}, DiscordTextChannel.Prototype)
	end)

	if channelData then
		for index, value in channelData do
			if self[index] ~= nil then
				continue
			end

			self[index] = value
		end
	end

	return self
end

export type DiscordTextChannel = typeof(DiscordTextChannel.Prototype) & {
	type: number,
	nsfw: boolean,
	id: string,
	flags: number,
	name: string,
	position: number,
	rateLimitPerUser: number,
	lastMessageId: string,
	guildId: string
}

export type DiscordTextChannelSchema = typeof(DiscordTextChannel.Prototype) & {
	name: string,
	position: number,
	topic: string,
	nsfw: boolean,
	rateLimitPerUser: number,
	parentId: string,
	defaultAutoArchiveDurection: number,
	defaultThreadRateLimitPerUser: number
}

return DiscordTextChannel.Interface