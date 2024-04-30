local DiscordComponentTypes = require("../../Types/DiscordComponent")

local Construct = require("../../Utils/Construct")

local CacheType = require("../../Enums/CacheType")
local DiscordEndpoints = require("../../Enums/DiscordEndpoints")

local Future = require("../../Vendor/Future")

--[=[
	@class Internal.DiscordMessage

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local DiscordMessage = {}

DiscordMessage.Prototype = {}
DiscordMessage.Interface = {}

DiscordMessage.Prototype.type = "DiscordMessage"

function DiscordMessage.Prototype.replyAsync(self: DiscordMessage, messageData: DiscordMessageSchema)
	return Future.try(function()
		local components = {}

		if messageData.components then
			for _, component in messageData.components do
				table.insert(components, component:toJSONObject())
			end
		end

		return self.discordClient.discordGateway:postAsync(string.format(DiscordEndpoints.BotCreateMessage, self.channelId), {
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
		local components = {}

		if messageData.components then
			for _, component in messageData.components do
				table.insert(components, component:toJSONObject())
			end
		end

		return self.discordClient.discordGateway:patchAsync(string.format(DiscordEndpoints.BotEditMessage, self.channelId, self.id), {
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

function DiscordMessage.Interface.new(discordClient: any, messageData: {
	id: string
})
	local self = discordClient.discordCache:getDataOr(CacheType.DiscordMessage, messageData.id, function()
		local messageStruct = {
			discordClient = discordClient
		}

		return Construct(messageStruct, DiscordMessage.Prototype)
	end)

	for index, value in messageData do
		self[index] = value
	end

	return self
end

export type DiscordMessage = typeof(DiscordMessage.Interface.new()) & {
	mentionRoles: { string },
	-- components: { unknown },
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
	-- embeds: { unknown },
	-- allowedMentions: { unknown },
	-- messageReference: {  },
	components: { DiscordComponentTypes.DiscordComponent },
	-- files: { unknown },
	-- payloadJson: { unknown }
	-- attachments: { unknown }
	stickerIds: { string }?,
	flags: number?,
	enforceNonce: boolean?
}

return DiscordMessage.Interface