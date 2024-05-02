local Construct = require("../../Utils/Construct")

local CacheType = require("../../Enums/CacheType")
local DiscordEndpoints = require("../../Enums/DiscordEndpoints")

local Future = require("../../Vendor/Future")

local DiscordMessage = require("../Internal/DiscordMessage")

--[=[
	@class Internal.DiscordTextChannel

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local DiscordTextChannel = {}

DiscordTextChannel.Prototype = {}
DiscordTextChannel.Interface = {}

DiscordTextChannel.Prototype.type = "DiscordTextChannel"

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