local Inherit = require("../../Utils/Inherit")

local DiscordEndpoints = require("../../Enums/DiscordEndpoints")

local Future = require("../../Vendor/Future")

local DiscordMessage = require("../Internal/DiscordMessage")
local DiscordMessageType = require("../../Types/DiscordMessage")

local DiscordTextChannel = require("DiscordTextChannel")
local DiscordVoiceChannel = require("DiscordVoiceChannel")
local DiscordInvite = require("DiscordInvite")

--[=[
	@class Internal.DiscordChannel

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local DiscordChannel = {}

DiscordChannel.Prototype = {}
DiscordChannel.Interface = {}

DiscordChannel.Prototype.type = "DiscordChannel"

function DiscordChannel.Prototype.triggerTypingIndicator(self: DiscordChannel)
	return Future.try(function()
		return self.discordClient.discordGateway:postAsync(string.format(DiscordEndpoints.BotTriggerTypingChannel, self.id), { }):await()
	end)
end

function DiscordChannel.Prototype.deleteAsync(self: DiscordChannel, messageIds: { string })
	return Future.try(function()
		return self.discordClient.discordGateway:deleteAsync(string.format(DiscordEndpoints.BotDeleteChannel, self.id)):await()
	end)
end

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

function DiscordChannel.Prototype.getMessageAsync(self: DiscordChannel, messageId: string)
	return Future.try(function()
		local messageObject = self.discordClient.discordGateway:getAsync(string.format(DiscordEndpoints.BotGetChannelMessage, self.id, messageId)):await()
		
		return DiscordMessage.new(self.discordClient, messageObject)
	end)
end

function DiscordChannel.Prototype.bulkDeleteMessagesAsync(self: DiscordChannel, messageIds: { string })
	return Future.try(function()
		return self.discordClient.discordGateway:postAsync(string.format(DiscordEndpoints.BotBulkDeleteMessages, self.id), {
			messages = messageIds
		}):await()
	end)
end

function DiscordChannel.Prototype.sendMessageAsync(self: DiscordChannel, messageData: DiscordMessageType.MessageSchema)
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

function DiscordChannel.Prototype.getInvitesAsync(self: DiscordChannel)
	return Future.try(function()
		local invites = self.discordClient.discordGateway:getAsync(string.format(DiscordEndpoints.BotGetInvites, self.id), { }):await()

		for index, inviteData in invites do
			invites[index] = DiscordInvite.new(self.discordClient, inviteData)
		end

		return invites
	end)
end

function DiscordChannel.Prototype.createInviteAsync(self: DiscordChannel, maxAge: number?, maxUses: number?, temporary: boolean?)
	return Future.try(function()
		local inviteData = self.discordClient.discordGateway:getAsync(string.format(DiscordEndpoints.BotGetInvites, self.id), {
			max_age = maxAge,
			max_uses = maxUses,
			temporary = temporary
		}):await()

		return DiscordInvite.new(self.discordClient, inviteData)
	end)
end

function DiscordChannel.Interface.new(discordClient: any, rawChannelData: any)
	-- https://discord.com/developers/docs/resources/channel#channel-object-channel-types
	-- todo: support other channel types lol

	local baseChannelObject

	if rawChannelData.type == 0 then
		baseChannelObject = DiscordTextChannel.new(discordClient, rawChannelData)
	elseif rawChannelData.type == 2 then
		baseChannelObject = DiscordVoiceChannel.new(discordClient, rawChannelData)
	else
		baseChannelObject = rawChannelData
	end

	return Inherit(DiscordChannel.Prototype, baseChannelObject)
end

export type DiscordChannel = (DiscordTextChannel.DiscordTextChannel | DiscordVoiceChannel.DiscordVoiceChannel) & typeof(DiscordChannel.Prototype)

return DiscordChannel.Interface