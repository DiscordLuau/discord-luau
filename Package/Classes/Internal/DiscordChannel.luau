local Construct = require("../../Utils/Construct")

local CacheType = require("../../Enums/CacheType")
local DiscordEndpoints = require("../../Enums/DiscordEndpoints")

local Future = require("../../Vendor/Future")

local DiscordMessageType = require("../../Types/DiscordMessage")

local DiscordUser = require("DiscordUser")

--[=[
	@class Internal.DiscordChannel

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local DiscordChannel = {}

DiscordChannel.Prototype = {}
DiscordChannel.Interface = {}

DiscordChannel.Prototype.type = "DiscordChannel"

function DiscordChannel.Prototype.sendMessageAsync(self: DiscordChannel, messageData: DiscordMessageType.MessageSchema)
	return Future.try(function()
		return self.discordClient.discordGateway:postAsync(string.format(DiscordEndpoints.BotCreateMessage, self.id), {
			content = messageData.content or nil,
			nonce = messageData.nonce or nil,
			tts = messageData.tts or false,
			sticker_ids = messageData.stickerIds,
			flags = messageData.flags or nil, --fixme: should use a bitfield.
			enforce_nonce = messageData.enforceNonce or false
		}):await()
	end)
end

function DiscordChannel.Interface.new(discordClient: any, channelData: {
	id: string,
	recipients: { any },
	[any]: any,
})
	return discordClient.discordCache:getDataOr(CacheType.DiscordChannel, channelData.id, function()
		local channelStruct = {
			discordClient = discordClient
		}

		if channelData.recipients then
			for index, value in channelData.recipients do
				channelData.recipients[index] = DiscordUser.new(discordClient, value)
			end
		end

		for index, value in channelData do
			channelStruct[index] = value
		end

		return Construct(channelStruct, DiscordChannel.Prototype)
	end)
end

export type DiscordChannel = typeof(DiscordChannel.Interface.new())

return DiscordChannel.Interface