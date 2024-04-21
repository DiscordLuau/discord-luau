local Construct = require("../../Utils/Construct")

local CacheType = require("../../Enums/CacheType")
local DiscordEndpoints = require("../../Enums/DiscordEndpoints")

local Future = require("../../Vendor/Future")

local DiscordMessageType = require("../../Types/DiscordMessage")

--[=[
	@class Internal.DiscordTextChannel

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local DiscordTextChannel = {}

DiscordTextChannel.Prototype = {}
DiscordTextChannel.Interface = {}

DiscordTextChannel.Prototype.type = "DiscordTextChannel"

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

return DiscordTextChannel.Interface