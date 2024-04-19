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
		return self.discordClient.discordGateway:postAsync(string.format(DiscordEndpoints.BotCreateMessage, self.channelId), {
			content = messageData.content or nil,
			nonce = messageData.nonce or nil,
			tts = messageData.tts or false,
			sticker_ids = messageData.stickerIds,
			flags = messageData.flags or nil, --fixme: should use a bitfield.
			enforce_nonce = messageData.enforceNonce or false
		}):await()
	end)
end

function DiscordMessage.Interface.new(discordClient: any, messageData: {
	id: string,
	[any]: any,
})
	return discordClient.discordCache:getDataOr(CacheType.DiscordMessage, messageData.id, function()
		local messageStruct = {
			discordClient = discordClient
		}

		for index, value in messageData do
			messageStruct[index] = value
		end

		return Construct(messageStruct, DiscordMessage.Prototype)
	end)
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
	-- components: { unknown },
	-- files: { unknown },
	-- payloadJson: { unknown }
	-- attachments: { unknown }
	stickerIds: { string }?,
	flags: number?,
	enforceNonce: boolean?
}

return DiscordMessage.Interface