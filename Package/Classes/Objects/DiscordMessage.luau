local DiscordComponentTypes = require("../../Types/DiscordComponent")

local Construct = require("../../Utils/Construct")

local CacheType = require("../../Enums/CacheType")
local DiscordEndpoints = require("../../Data/DiscordEndpoints")

local EmbedBuilder = require("../Builders/EmbedBuilder")
local MessageBuilder = require("../Builders/MessageBuilder")
local DiscordGuildMember = require("../Objects/DiscordGuildMember")

local Future = require("../../Vendor/Future")

local Net = require("../../Std/Net")

--[=[
	@class Objects.DiscordMessage

	DiscordMessage represents a message in a Discord channel, providing methods to reply, delete, pin, unpin, edit, and manage reactions.
]=]
local DiscordMessage = {}

DiscordMessage.Prototype = {}
DiscordMessage.Interface = {}

DiscordMessage.Prototype.type = "DiscordMessage"

--[=[
	Replies to the message asynchronously.
	
	@method replyAsync
	@param messageBuilder MessageBuilder -- The message builder containing the reply content.
	@return Future<unknown> -- A future that resolves when the reply is sent.
	@within Objects.DiscordMessage
]=]
function DiscordMessage.Prototype.replyAsync(self: DiscordMessage, messageBuilder: MessageBuilder.MessageBuilder)
	return Future.try(function()
		return self.discordClient.discordGateway:postAsync(
			string.format(DiscordEndpoints.BotCreateMessage, self.channelId),
			messageBuilder:toJSONObject()
		):await()
	end)
end

--[=[
	Deletes the message asynchronously.
	
	@method deleteAsync
	@return Future<unknown> -- A future that resolves when the message is deleted.
	@within Objects.DiscordMessage
]=]
function DiscordMessage.Prototype.deleteAsync(self: DiscordMessage)
	return Future.try(function()
		return self.discordClient.discordGateway:deleteAsync(string.format(DiscordEndpoints.BotDeleteMessage, self.channelId, self.id)):await()
	end)
end

--[=[
	Pins the message asynchronously.
	
	@method pinAsync
	@return Future<unknown> -- A future that resolves when the message is pinned.
	@within Objects.DiscordMessage
]=]
function DiscordMessage.Prototype.pinAsync(self: DiscordMessage)
	return Future.try(function()
		return self.discordClient.discordGateway:putAsync(string.format(DiscordEndpoints.BotPinMessage, self.channelId, self.id)):await()
	end)
end

--[=[
	Unpins the message asynchronously.
	
	@method unpinAsync
	@return Future<unknown> -- A future that resolves when the message is unpinned.
	@within Objects.DiscordMessage
]=]
function DiscordMessage.Prototype.unpinAsync(self: DiscordMessage)
	return Future.try(function()
		return self.discordClient.discordGateway:deleteAsync(string.format(DiscordEndpoints.BotUnpinMessage, self.channelId, self.id)):await()
	end)
end

--[=[
	Edits the message asynchronously.
	
	@method editAsync
	@param messageBuilder MessageBuilder -- The message builder containing the new content.
	@within Objects.DiscordMessage
	@return Future<unknown> -- A future that resolves when the message is edited.
]=]
function DiscordMessage.Prototype.editAsync(self: DiscordMessage, messageBuilder: MessageBuilder.MessageBuilder)
	return Future.try(function()
		return self.discordClient.discordGateway:patchAsync(
			string.format(DiscordEndpoints.BotEditMessage, self.channelId, self.id),
			messageBuilder:toJSONObject()
		):await()
	end)
end

--[=[
	Adds a reaction to the message asynchronously.
	
	@method addReactionAsync
	@param reaction string -- The reaction to be added.
	@within Objects.DiscordMessage
	@return Future<unknown> -- A future that resolves when the reaction is added.
]=]
function DiscordMessage.Prototype.addReactionAsync(self: DiscordMessage, reaction: string)
	return Future.try(function()
		local isBinary = string.find(reaction, ":") == nil

		return self.discordClient.discordGateway:putAsync(
			string.format(DiscordEndpoints.BotCreateReaction, self.channelId, self.id, Net.urlEncode(reaction, isBinary)), { }
		):await()
	end)
end

--[=[
	Removes a reaction from the message asynchronously.
	
	@method removeReactionAsync
	@param reaction string -- The reaction to be removed.
	@within Objects.DiscordMessage
	@return Future<unknown> -- A future that resolves when the reaction is removed.
]=]
function DiscordMessage.Prototype.removeReactionAsync(self: DiscordMessage, reaction: string)
	return Future.try(function()
		local isBinary = string.find(reaction, ":") == nil

		return self.discordClient.discordGateway:deleteAsync(
			string.format(DiscordEndpoints.BotDeleteReaction, self.channelId, self.id, Net.urlEncode(reaction, isBinary)), { }
		):await()
	end)
end

--[=[
	
	Removes a reaction from a specific user on the message asynchronously.
	
	@method removeUserReactionAsync
	@param userId string -- The ID of the user whose reaction is to be removed.
	@param reaction string -- The reaction to be removed.
	@within Objects.DiscordMessage
	@return Future<unknown> -- A future that resolves when the user's reaction is removed.
]=]
function DiscordMessage.Prototype.removeUserReactionAsync(self: DiscordMessage, userId: string, reaction: string)
	return Future.try(function()
		local isBinary = string.find(reaction, ":") == nil

		return self.discordClient.discordGateway:deleteAsync(
			string.format(DiscordEndpoints.BotDeleteUserReaction, self.channelId, self.id, Net.urlEncode(reaction, isBinary), userId), { }
		):await()
	end)
end

--[=[
	Gets the reactions on the message asynchronously.
	
	@method getReactionsAsync
	@param reaction string -- The reaction to retrieve.
	@within Objects.DiscordMessage
	@return Future<unknown> -- A future that resolves to the reactions.
]=]
function DiscordMessage.Prototype.getReactionsAsync(self: DiscordMessage, reaction: string)
	return Future.try(function()
		local isBinary = string.find(reaction, ":") == nil

		return self.discordClient.discordGateway:getAsync(
			string.format(DiscordEndpoints.BotGetReactions, self.channelId, self.id, Net.urlEncode(reaction, isBinary)), { }
		):await()
	end)
end

--[=[
	Removes all reactions from the message asynchronously.
	
	@method removeAllReactionsAsync
	@return Future<unknown> -- A future that resolves when all reactions are removed.
	@within Objects.DiscordMessage
]=]
function DiscordMessage.Prototype.removeAllReactionsAsync(self: DiscordMessage)
	return Future.try(function()
		return self.discordClient.discordGateway:deleteAsync(
			string.format(DiscordEndpoints.BotDeleteAllReactions, self.channelId, self.id), { }
		):await()
	end)
end

--[=[
	Removes all reactions for a specific emoji from the message asynchronously.
	
	@method removeAllReactionsForEmojiAsync
	@param reaction string -- The emoji whose reactions are to be removed.
	@within Objects.DiscordMessage
	@return Future<unknown> -- A future that resolves when the reactions for the emoji are removed.
]=]
function DiscordMessage.Prototype.removeAllReactionsForEmojiAsync(self: DiscordMessage, reaction: string)
	return Future.try(function()
		local isBinary = string.find(reaction, ":") == nil

		return self.discordClient.discordGateway:deleteAsync(
			string.format(DiscordEndpoints.BotDeleteAllReactionsForEmoji, self.channelId, self.id, Net.urlEncode(reaction, isBinary)), { }
		):await()
	end)
end

--[=[
	Creates a new instance of DiscordMessage.
	
	@function new
	@param discordClient any -- The Discord client instance.
	@param messageData table -- The data for the message to be created.
	@within Objects.DiscordMessage
	@return DiscordMessage -- A new instance of DiscordMessage.
]=]
function DiscordMessage.Interface.new(discordClient: any, messageData: {
	id: string,

	guildId: string,
	channelId: string,

	author: {
		username: string,
		avatar: string,
		id: string,
		bot: boolean,
		discriminator: string,
		publicFlags: number
	},

	member: {
		[any]: any
	}
})
	local self = discordClient.discordCache:getDataOr(CacheType.DiscordMessage, messageData.id, function()
		local messageStruct = {
			discordClient = discordClient
		}

		messageData.member = DiscordGuildMember.new(discordClient, messageData.author.id, messageData.guildId, messageData.member)

		return Construct(messageStruct, DiscordMessage.Prototype)
	end)

	for index, value in messageData do
		self[index] = value
	end

	return self
end

export type DiscordMessage = typeof(DiscordMessage.Prototype) & {
	discordClient: any,

	mentionRoles: { string },
	components: { DiscordComponentTypes.DiscordComponent },
	-- attachments: { unknown },
	-- embeds: { unknown },
	tts: boolean,
	mentionEveryone: boolean,
	nonce: string,
	id: string,
	author: {
		username: string,
		globalName: string,
		avatar: string,
		id: string,
		publicFlags: number,
		discriminator: string,
	},
	content: string,
	mentions: { string },
	flags: number,
	timestamp: string,
	type: number,
	pinned: boolean,
	guildId: boolean,
	channelId: boolean,
	member: {
		flags: number,
		deaf: boolean,
		roles: { [string]: string },
		pending: boolean,
		mute: boolean,
		joinedAt: string
	},
}

return DiscordMessage.Interface
