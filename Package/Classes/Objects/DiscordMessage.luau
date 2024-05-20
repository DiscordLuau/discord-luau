local DiscordComponentTypes = require("../../Types/DiscordComponent")

local Construct = require("../../Utils/Construct")

local CacheType = require("../../Enums/CacheType")
local DiscordEndpoints = require("../../Data/DiscordEndpoints")

local DiscordEmbedBuilder = require("../Builders/DiscordEmbedBuilder")
local DiscordGuildMember = require("../Objects/DiscordGuildMember")

local Future = require("../../Vendor/Future")

local Net = require("../../Std/Net")

--[=[
	@class Objects.DiscordMessage

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local DiscordMessage = {}

DiscordMessage.Prototype = {}
DiscordMessage.Interface = {}

DiscordMessage.Prototype.type = "DiscordMessage"

function DiscordMessage.Prototype.replyAsync(self: DiscordMessage, messageData: DiscordMessageSchema)
	return Future.try(function()
		return self.discordClient.discordGateway:postAsync(
			string.format(DiscordEndpoints.BotCreateMessage, self.channelId),
			DiscordMessage.Interface.intoJson(messageData)
		):await()
	end)
end

function DiscordMessage.Prototype.deleteAsync(self: DiscordMessage)
	return Future.try(function()
		return self.discordClient.discordGateway:deleteAsync(string.format(DiscordEndpoints.BotDeleteMessage, self.channelId, self.id)):await()
	end)
end

function DiscordMessage.Prototype.pinAsync(self: DiscordMessage)
	return Future.try(function()
		return self.discordClient.discordGateway:putAsync(string.format(DiscordEndpoints.BotPinMessage, self.channelId, self.id)):await()
	end)
end

function DiscordMessage.Prototype.unpinAsync(self: DiscordMessage)
	return Future.try(function()
		return self.discordClient.discordGateway:deleteAsync(string.format(DiscordEndpoints.BotUnpinMessage, self.channelId, self.id)):await()
	end)
end

function DiscordMessage.Prototype.editAsync(self: DiscordMessage, messageData: DiscordMessageSchema)
	return Future.try(function()
		return self.discordClient.discordGateway:patchAsync(
			string.format(DiscordEndpoints.BotEditMessage, self.channelId, self.id),
			DiscordMessage.Interface.intoJson(messageData)
		):await()
	end)
end

function DiscordMessage.Prototype.addReactionAsync(self: DiscordMessage, reaction: string)
	return Future.try(function()
		local isBinary = string.find(reaction, ":") == nil

		return self.discordClient.discordGateway:putAsync(
			string.format(DiscordEndpoints.BotCreateReaction, self.channelId, self.id, Net.urlEncode(reaction, isBinary)), { }
		):await()
	end)
end

function DiscordMessage.Prototype.removeReactionAsync(self: DiscordMessage, reaction: string)
	return Future.try(function()
		local isBinary = string.find(reaction, ":") == nil

		return self.discordClient.discordGateway:deleteAsync(
			string.format(DiscordEndpoints.BotDeleteReaction, self.channelId, self.id, Net.urlEncode(reaction, isBinary)), { }
		):await()
	end)
end

function DiscordMessage.Prototype.removeUserReactionAsync(self: DiscordMessage, userId: string, reaction: string)
	return Future.try(function()
		local isBinary = string.find(reaction, ":") == nil

		return self.discordClient.discordGateway:deleteAsync(
			string.format(DiscordEndpoints.BotDeleteUserReaction, self.channelId, self.id, Net.urlEncode(reaction, isBinary), userId), { }
		):await()
	end)
end

function DiscordMessage.Prototype.getReactionsAsync(self: DiscordMessage, reaction: string)
	return Future.try(function()
		local isBinary = string.find(reaction, ":") == nil

		return self.discordClient.discordGateway:getAsync(
			string.format(DiscordEndpoints.BotGetReactions, self.channelId, self.id, Net.urlEncode(reaction, isBinary)), { }
		):await()
	end)
end

function DiscordMessage.Prototype.removeAllReactionsAsync(self: DiscordMessage)
	return Future.try(function()
		return self.discordClient.discordGateway:deleteAsync(
			string.format(DiscordEndpoints.BotDeleteAllReactions, self.channelId, self.id), { }
		):await()
	end)
end

function DiscordMessage.Prototype.removeAllReactionsForEmojiAsync(self: DiscordMessage, reaction: string)
	return Future.try(function()
		local isBinary = string.find(reaction, ":") == nil

		return self.discordClient.discordGateway:deleteAsync(
			string.format(DiscordEndpoints.BotDeleteAllReactionsForEmoji, self.channelId, self.id, Net.urlEncode(reaction, isBinary)), { }
		):await()
	end)
end

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

function DiscordMessage.Interface.intoJson(messageSchema: DiscordMessageSchema)
	local components = {}
	local embeds = {}

	if messageSchema.components then
		for _, component in messageSchema.components do
			table.insert(components, (component :: any):toJSONObject())
		end
	end

	if messageSchema.embeds then
		for _, embed in messageSchema.embeds do
			table.insert(embeds, embed:toJSONObject())
		end
	end

	return {
		content = messageSchema.content or nil,
		nonce = messageSchema.nonce or nil,
		tts = messageSchema.tts or false,
		sticker_ids = messageSchema.stickerIds,
		flags = messageSchema.flags or nil, --fixme: should use a bitfield.
		enforce_nonce = messageSchema.enforceNonce or false,

		embeds = embeds,
		components = components,
	}
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

export type DiscordMessageSchema = {
	content: string?,
	nonce: (string | number)?,
	tts: boolean?,
	embeds: { DiscordEmbedBuilder.DiscordEmbedBuilder }?,
	-- allowedMentions: { unknown },
	-- messageReference: {  },
	components: { DiscordComponentTypes.DiscordComponent }?,
	-- files: { unknown },
	-- payloadJson: { unknown }
	-- attachments: { unknown }
	stickerIds: { string }?,
	flags: number?,
	enforceNonce: boolean?
}

return DiscordMessage.Interface