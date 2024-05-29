local Construct = require("../../Utils/Construct")

local CacheType = require("../../Enums/CacheType")
local DiscordEndpoints = require("../../Data/DiscordEndpoints")

local Future = require("../../Vendor/Future")

local DiscordMessage = require("../Objects/DiscordMessage")

local Resolvable = require("../Network/Resolvable")
local ResolvableType = require("../../Enums/ResolveableType")

--[=[
	@class Objects.DiscordAnnouncementChannel

	DiscordAnnouncementChannel represents a text channel in a Discord server, providing methods to modify the channel and interact with pinned messages.
]=]
local DiscordAnnouncementChannel = {}

DiscordAnnouncementChannel.Prototype = {}
DiscordAnnouncementChannel.Interface = {}

DiscordAnnouncementChannel.Prototype.type = "DiscordAnnouncementChannel"

--[=[
	Modifies the text channel settings asynchronously.
	
	@method modifyAsync
	@param channelSchema DiscordAnnouncementChannelSchema -- The schema containing the modifications to be applied.
	@within Objects.DiscordAnnouncementChannel
	@return Future<unknown> -- A future that resolves when the modifications are complete.
]=]
function DiscordAnnouncementChannel.Prototype.modifyAsync(
	self: DiscordAnnouncementChannel,
	channelSchema: DiscordAnnouncementChannelSchema
)
	return Future.try(function()
		return self.discordClient.discordGateway
			:patchAsync(
				string.format(DiscordEndpoints.BotModifyChannel, self.id),
				Resolvable.new(ResolvableType.JSON, {
					name = channelSchema.name,
					position = channelSchema.position,
					topic = channelSchema.topic,
					nsfw = channelSchema.nsfw,
					rate_limit_per_user = channelSchema.rateLimitPerUser,
					parent_id = channelSchema.parentId,
					default_auto_archive_duration = channelSchema.defaultAutoArchiveDurection,
					default_thread_rate_limit_per_user = channelSchema.defaultThreadRateLimitPerUser,
				})
			)
			:await()
	end)
end

--[=[
	Retrieves the pinned messages in the text channel asynchronously.
	
	@method getPinnedMessagesAsync
	@within Objects.DiscordAnnouncementChannel
	@return Future<{[number]: DiscordMessage}> -- A future that resolves to an array of pinned messages.
]=]
function DiscordAnnouncementChannel.Prototype.getPinnedMessagesAsync(self: DiscordAnnouncementChannel)
	return Future.try(function()
		local messages = self.discordClient.discordGateway
			:getAsync(string.format(DiscordEndpoints.BotGetPinnedMessages, self.id))
			:await()

		for index, messageData in messages do
			messages[index] = DiscordMessage.new(self.discordClient, messageData)
		end

		return messages
	end)
end

--[=[
	allows this channel object to follow another announcement channel.
	
	@method followChannelAsync
	@param channelId string
	@within Objects.DiscordAnnouncementChannel
	@return Future<{[number]: DiscordMessage}> -- A future that resolves to an array of pinned messages.
]=]
function DiscordAnnouncementChannel.Prototype.followChannelAsync(self: DiscordAnnouncementChannel, channelId: string)
	return Future.try(function()
		return self.discordClient.discordGateway
			:postAsync(
				string.format(DiscordEndpoints.BotFollowAnnouncementChannel, self.id),
				Resolvable.new(ResolvableType.JSON, {
					webhook_channel_id = channelId,
				})
			)
			:await()
	end)
end

--[=[
	Creates a new instance of DiscordAnnouncementChannel.
	
	@function new
	@param discordClient any -- The Discord client instance.
	@param channelData table -- The data for the channel to be created.
	@within Objects.DiscordAnnouncementChannel
	@return DiscordAnnouncementChannel -- A new instance of DiscordAnnouncementChannel.
]=]
function DiscordAnnouncementChannel.Interface.new(
	discordClient: any,
	channelData: {
		id: string,
		recipients: { unknown },
	}
): DiscordAnnouncementChannel
	local self = discordClient.discordCache:getDataOr(CacheType.DiscordAnnouncementChannel, channelData.id, function()
		return Construct({
			id = channelData.id,

			discordClient = discordClient,
		}, DiscordAnnouncementChannel.Prototype)
	end)

	if channelData then
		for index, value in channelData do
			self[index] = value
		end
	end

	return self
end

export type DiscordAnnouncementChannel = typeof(DiscordAnnouncementChannel.Prototype) & {
	discordClient: any,

	type: number,
	nsfw: boolean,
	id: string,
	flags: number,
	name: string,
	position: number,
	rateLimitPerUser: number,
	lastMessageId: string,
	guildId: string,
}

export type DiscordAnnouncementChannelSchema = {
	name: string,
	position: number,
	topic: string,
	nsfw: boolean,
	rateLimitPerUser: number,
	parentId: string,
	defaultAutoArchiveDurection: number,
	defaultThreadRateLimitPerUser: number,
}

return DiscordAnnouncementChannel.Interface
