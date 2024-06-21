local Future = require("@dep/future")

local Net = require("@std/net")

local construct = require("@util/construct")

local DiscordEndpoints = require("@data/endpoints")

local Resolvable = require("@network/resolvable")

local MessageBuilder = require("@builders/message")
local DiscordGuildMember = require("@classes/guild/member")

local ActionRowBuilder = require("@builders/interface/actionRow")
local ButtonBuilder = require("@builders/interface/button")
local SelectionBuilder = require("@builders/interface/selection")
local TextInputBuilder = require("@builders/interface/textInput")

local ResolvableType = require("@enums/resolvableType")
local CacheType = require("@enums/cacheType")

--[=[
	@class Objects.DiscordMessage

	DiscordMessage represents a message in a Discord channel, providing methods to reply, delete, pin, unpin, edit, and manage reactions.
]=]
local DiscordMessage = {}

DiscordMessage.Prototype = {}
DiscordMessage.Interface = {}

DiscordMessage.Prototype.type = "DiscordMessage"

--[=[
	Crossposts the message in an Announcement Channel to all following channels.
	
	@method crosspostAsync
	@return Vendor.Future<Objects.DiscordMessage>
	@within Objects.DiscordMessage
]=]
function DiscordMessage.Prototype.crosspostAsync(self: DiscordMessage)
	return Future.try(function()
		local messageObject = self.discordClient.discordGateway
			:postAsync(string.format(DiscordEndpoints.BotCrosspostMessage, self.channelId, self.id))
			:await()

		return DiscordMessage.Interface.new(self.discordClient, messageObject)
	end)
end

--[=[
	Replies to the message asynchronously.
	
	@method replyAsync
	@param messageBuilder MessageBuilder -- The message builder containing the reply content.
	@return Vendor.Future<unknown> -- A future that resolves when the reply is sent.
	@within Objects.DiscordMessage
]=]
function DiscordMessage.Prototype.replyAsync(self: DiscordMessage, messageBuilder: MessageBuilder.MessageBuilder)
	return Future.try(function()
		return self.discordClient.discordGateway
			:postAsync(
				string.format(DiscordEndpoints.BotCreateMessage, self.channelId),
				messageBuilder:toPayloadObject()
			)
			:await()
	end)
end

--[=[
	Start a thread from the current message object. 
	
	@method startThreadAsync
	@param name string
	@param autoArchiveDuration: number
	@param rateLimitPerUser: number?
	@return Vendor.Future<string>
	@within Objects.DiscordMessage
]=]
function DiscordMessage.Prototype.startThreadAsync(
	self: DiscordMessage,
	name: string,
	autoArchiveDuration: number,
	rateLimitPerUser: number?
)
	return Future.try(function()
		local threadChannel = self.discordClient.discordGateway
			:postAsync(
				string.format(DiscordEndpoints.BotCreateThreadFromMessage, self.channelId, self.id),
				Resolvable.new(ResolvableType.JSON, {
					name = name,
					auto_archive_duration = autoArchiveDuration,
					rate_limit_per_user = rateLimitPerUser,
				})
			)
			:await()

		-- fixme: man this sucks, discordChannel requires DiscordMessage - so we can't create the object for you
		-- you'll need to call :getChannelAsync through the client.. sorry.

		return threadChannel.id
	end)
end

--[=[
	Deletes the message asynchronously.
	
	@method deleteAsync
	@return Vendor.Future<unknown> -- A future that resolves when the message is deleted.
	@within Objects.DiscordMessage
]=]
function DiscordMessage.Prototype.deleteAsync(self: DiscordMessage)
	return Future.try(function()
		return self.discordClient.discordGateway
			:deleteAsync(string.format(DiscordEndpoints.BotDeleteMessage, self.channelId, self.id))
			:await()
	end)
end

--[=[
	Pins the message asynchronously.
	
	@method pinAsync
	@return Vendor.Future<unknown> -- A future that resolves when the message is pinned.
	@within Objects.DiscordMessage
]=]
function DiscordMessage.Prototype.pinAsync(self: DiscordMessage)
	return Future.try(function()
		return self.discordClient.discordGateway
			:putAsync(string.format(DiscordEndpoints.BotPinMessage, self.channelId, self.id))
			:await()
	end)
end

--[=[
	Unpins the message asynchronously.
	
	@method unpinAsync
	@return Vendor.Future<unknown> -- A future that resolves when the message is unpinned.
	@within Objects.DiscordMessage
]=]
function DiscordMessage.Prototype.unpinAsync(self: DiscordMessage)
	return Future.try(function()
		return self.discordClient.discordGateway
			:deleteAsync(string.format(DiscordEndpoints.BotUnpinMessage, self.channelId, self.id))
			:await()
	end)
end

--[=[
	Edits the message asynchronously.
	
	@method editAsync
	@param messageBuilder MessageBuilder -- The message builder containing the new content.
	@within Objects.DiscordMessage
	@return Vendor.Future<unknown> -- A future that resolves when the message is edited.
]=]
function DiscordMessage.Prototype.editAsync(self: DiscordMessage, messageBuilder: MessageBuilder.MessageBuilder)
	return Future.try(function()
		return self.discordClient.discordGateway
			:patchAsync(
				string.format(DiscordEndpoints.BotEditMessage, self.channelId, self.id),
				messageBuilder:toPayloadObject()
			)
			:await()
	end)
end

--[=[
	Adds a reaction to the message asynchronously.
	
	@method addReactionAsync
	@param reaction string -- The reaction to be added.
	@within Objects.DiscordMessage
	@return Vendor.Future<unknown> -- A future that resolves when the reaction is added.
]=]
function DiscordMessage.Prototype.addReactionAsync(self: DiscordMessage, reaction: string)
	return Future.try(function()
		local isBinary = string.find(reaction, ":") == nil

		return self.discordClient.discordGateway
			:putAsync(
				string.format(
					DiscordEndpoints.BotCreateReaction,
					self.channelId,
					self.id,
					Net.urlEncode(reaction, isBinary)
				)
			)
			:await()
	end)
end

--[=[
	Removes a reaction from the message asynchronously.
	
	@method removeReactionAsync
	@param reaction string -- The reaction to be removed.
	@within Objects.DiscordMessage
	@return Vendor.Future<unknown> -- A future that resolves when the reaction is removed.
]=]
function DiscordMessage.Prototype.removeReactionAsync(self: DiscordMessage, reaction: string)
	return Future.try(function()
		local isBinary = string.find(reaction, ":") == nil

		return self.discordClient.discordGateway
			:deleteAsync(
				string.format(
					DiscordEndpoints.BotDeleteReaction,
					self.channelId,
					self.id,
					Net.urlEncode(reaction, isBinary)
				)
			)
			:await()
	end)
end

--[=[
	
	Removes a reaction from a specific user on the message asynchronously.
	
	@method removeUserReactionAsync
	@param userId string -- The ID of the user whose reaction is to be removed.
	@param reaction string -- The reaction to be removed.
	@within Objects.DiscordMessage
	@return Vendor.Future<unknown> -- A future that resolves when the user's reaction is removed.
]=]
function DiscordMessage.Prototype.removeUserReactionAsync(self: DiscordMessage, userId: string, reaction: string)
	return Future.try(function()
		local isBinary = string.find(reaction, ":") == nil

		return self.discordClient.discordGateway
			:deleteAsync(
				string.format(
					DiscordEndpoints.BotDeleteUserReaction,
					self.channelId,
					self.id,
					Net.urlEncode(reaction, isBinary),
					userId
				)
			)
			:await()
	end)
end

--[=[
	Gets the reactions on the message asynchronously.
	
	@method getReactionsAsync
	@param reaction string -- The reaction to retrieve.
	@within Objects.DiscordMessage
	@return Vendor.Future<unknown> -- A future that resolves to the reactions.
]=]
function DiscordMessage.Prototype.getReactionsAsync(self: DiscordMessage, reaction: string)
	return Future.try(function()
		local isBinary = string.find(reaction, ":") == nil

		return self.discordClient.discordGateway
			:getAsync(
				string.format(
					DiscordEndpoints.BotGetReactions,
					self.channelId,
					self.id,
					Net.urlEncode(reaction, isBinary)
				)
			)
			:await()
	end)
end

--[=[
	Removes all reactions from the message asynchronously.
	
	@method removeAllReactionsAsync
	@return Vendor.Future<unknown> -- A future that resolves when all reactions are removed.
	@within Objects.DiscordMessage
]=]
function DiscordMessage.Prototype.removeAllReactionsAsync(self: DiscordMessage)
	return Future.try(function()
		return self.discordClient.discordGateway
			:deleteAsync(string.format(DiscordEndpoints.BotDeleteAllReactions, self.channelId, self.id))
			:await()
	end)
end

--[=[
	Removes all reactions for a specific emoji from the message asynchronously.
	
	@method removeAllReactionsForEmojiAsync
	@param reaction string -- The emoji whose reactions are to be removed.
	@within Objects.DiscordMessage
	@return Vendor.Future<unknown> -- A future that resolves when the reactions for the emoji are removed.
]=]
function DiscordMessage.Prototype.removeAllReactionsForEmojiAsync(self: DiscordMessage, reaction: string)
	return Future.try(function()
		local isBinary = string.find(reaction, ":") == nil

		return self.discordClient.discordGateway
			:deleteAsync(
				string.format(
					DiscordEndpoints.BotDeleteAllReactionsForEmoji,
					self.channelId,
					self.id,
					Net.urlEncode(reaction, isBinary)
				)
			)
			:await()
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
function DiscordMessage.Interface.new(
	discordClient: any,
	messageData: {
		id: string,

		guildId: string,
		channelId: string,

		author: {
			username: string,
			avatar: string,
			id: string,
			bot: boolean,
			discriminator: string,
			publicFlags: number,
		},

		member: {
			[any]: any,
		},
	}
)
	--[=[
		@prop mentionRoles { string }
		@within Objects.DiscordMessage
	]=]

	--[=[
		@prop tts boolean
		@within Objects.DiscordMessage
	]=]

	--[=[
		@prop mentionEveryone boolean
		@within Objects.DiscordMessage
	]=]

	--[=[
		@prop nonce string
		@within Objects.DiscordMessage
	]=]

	--[=[
		@prop id string
		@within Objects.DiscordMessage
	]=]

	--[=[
		@prop author { username: string, globalName: string, avatar: string, id: string, publicFlags: number, discriminator: string }
		@within Objects.DiscordMessage
	]=]

	--[=[
		@prop content string
		@within Objects.DiscordMessage
	]=]

	--[=[
		@prop mentions { string }
		@within Objects.DiscordMessage
	]=]

	--[=[
		@prop flags string
		@within Objects.DiscordMessage
	]=]

	--[=[
		@prop timestamp string
		@within Objects.DiscordMessage
	]=]

	--[=[
		@prop type number
		@within Objects.DiscordMessage
	]=]

	--[=[
		@prop pinned boolean
		@within Objects.DiscordMessage
	]=]

	--[=[
		@prop guildId string
		@within Objects.DiscordMessage
	]=]

	--[=[
		@prop channelId string
		@within Objects.DiscordMessage
	]=]

	--[=[
		@prop member { flags: number, deaf: boolean, roles: { [string]: string }, pending: boolean, mute: boolean, joinedAt: string }
		@within Objects.DiscordMessage
	]=]
	local self = discordClient.discordCache:getDataOr(CacheType.DiscordMessage, messageData.id, function()
		local messageStruct = {
			discordClient = discordClient,
		}

		if messageData.member then
			messageData.member =
				DiscordGuildMember.new(discordClient, messageData.author.id, messageData.guildId, messageData.member)
		end
		if messageData.guildId then
			local discordChannel = discordClient.discordCache:getData(CacheType.DiscordChannel, messageData.guildId)

			if discordChannel then
				discordChannel.lastMessageId = messageData.id
			end
		end

		return construct(messageStruct, DiscordMessage.Prototype)
	end)

	for index, value in messageData do
		self[index] = value
	end

	return self
end

type InterfaceBuidler =
	ActionRowBuilder.ActionRowBuilder
	| ButtonBuilder.ButtonBuilder
	| SelectionBuilder.SelectionBuilder
	| TextInputBuilder.TextInputBuilder

export type DiscordMessage = typeof(DiscordMessage.Prototype) & {
	discordClient: any,

	mentionRoles: { string },
	-- components: { InterfaceBuidler }, -- todo: add components to message
	-- attachments: { unknown }, -- todo: add attachments from messages
	-- embeds: { unknown }, -- todo: add embeds from messages
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
	flags: string,
	timestamp: string,
	type: number,
	pinned: boolean,
	guildId: string,
	channelId: string,
	member: {
		flags: number,
		deaf: boolean,
		roles: { [string]: string },
		pending: boolean,
		mute: boolean,
		joinedAt: string,
	},
}

return DiscordMessage.Interface
