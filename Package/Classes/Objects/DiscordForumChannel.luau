local Construct = require("../../Utils/Construct")

local CacheType = require("../../Enums/CacheType")
local DiscordEndpoints = require("../../Data/DiscordEndpoints")

local Future = require("../../Vendor/Future")

local MessageBuilder = require("../Builders/MessageBuilder")

local DiscordMessage = require("../Objects/DiscordMessage")
local DiscordGuildMember = require("../Objects/DiscordGuildMember")

local Resolvable = require("../Network/Resolvable")
local ResolvableType = require("../../Enums/ResolveableType")

--[=[
	@class Objects.DiscordForumChannel

	DiscordForumChannel represents a thread channel in a Discord server, providing methods to modify the channel and interact with pinned messages.
]=]
local DiscordForumChannel = {}

DiscordForumChannel.Prototype = {}
DiscordForumChannel.Interface = {}

DiscordForumChannel.Prototype.type = "DiscordForumChannel"

--[=[
	Create a new thread inside of a Forum channel.
	
	@method createThreadAsync
	@param name string
	@param message MessageBuilder
	@param appliedTags { string }?
	@param autoArchiveDuration number?
	@param rateLimitPerUser number?
	@within Objects.DiscordForumChannel
	@return Future<unknown>
]=]
function DiscordForumChannel.Prototype.createThreadAsync(
	self: DiscordForumChannel,
	name: string,
	message: MessageBuilder.MessageBuilder,
	appliedTags: { string }?,
	autoArchiveDuration: number?,
	rateLimitPerUser: number?
)
	return Future.try(function()
		return self.discordClient.discordGateway
			:postAsync(
				string.format(DiscordEndpoints.BotCreateForumOrMediaThread, self.id),
				message:toPayloadObject():update(function(data)
					return {
						name = name,
						message = data,
						rate_limit_per_user = rateLimitPerUser,
						auto_archive_duration = autoArchiveDuration,
						applied_tags = appliedTags,
					}
				end)
			)
			:await()
	end)
end

--[=[
	Modifies the thread channel settings asynchronously.
	
	@method modifyAsync
	@param channelSchema DiscordTextChannelSchema -- The schema containing the modifications to be applied.
	@within Objects.DiscordForumChannel
	@return Future<unknown> -- A future that resolves when the modifications are complete.
]=]
function DiscordForumChannel.Prototype.modifyAsync(self: DiscordForumChannel, channelSchema)
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
	Retrieves the pinned messages in the thread channel asynchronously.
	
	@method getPinnedMessagesAsync
	@within Objects.DiscordForumChannel
	@return Future<{[number]: DiscordMessage}> -- A future that resolves to an array of pinned messages.
]=]
function DiscordForumChannel.Prototype.getPinnedMessagesAsync(self: DiscordForumChannel)
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
	Creates a new instance of DiscordForumChannel.
	
	@function new
	@param discordClient any -- The Discord client instance.
	@param channelData table -- The data for the channel to be created.
	@within Objects.DiscordForumChannel
	@return DiscordForumChannel -- A new instance of DiscordForumChannel.
]=]
function DiscordForumChannel.Interface.new(
	discordClient: any,
	channelData: {
		id: string,
		recipients: { unknown },
	}
): DiscordForumChannel
	local self = discordClient.discordCache:getDataOr(CacheType.DiscordForumChannel, channelData.id, function()
		return Construct({
			id = channelData.id,

			discordClient = discordClient,
		}, DiscordForumChannel.Prototype)
	end)

	if channelData then
		for index, value in channelData do
			self[index] = value
		end
	end

	return self
end

export type DiscordForumChannel = typeof(DiscordForumChannel.Prototype) & {
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

return DiscordForumChannel.Interface
