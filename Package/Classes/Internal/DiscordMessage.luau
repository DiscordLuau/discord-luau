local Construct = require("../../Utils/Construct")

local CacheType = require("../../Enums/CacheType")
local DiscordEndpoints = require("../../Enums/DiscordEndpoints")

local Future = require("../../Vendor/Future")

local DiscordMessageType = require("../../Types/DiscordMessage")

--[=[
	@class Internal.DiscordMessage

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local DiscordMessage = {}

DiscordMessage.Prototype = {}
DiscordMessage.Interface = {}

DiscordMessage.Prototype.type = "DiscordMessage"

function DiscordMessage.Prototype.replyAsync(self: DiscordMessage, messageData: DiscordMessageType.MessageSchema)
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

export type DiscordMessage = typeof(DiscordMessage.Interface.new()) & DiscordMessageType.DiscordMessage

return DiscordMessage.Interface