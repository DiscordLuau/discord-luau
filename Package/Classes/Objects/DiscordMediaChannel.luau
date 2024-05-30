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
	@class Objects.DiscordMediaChannel

	DiscordMediaChannel represents a thread channel in a Discord server, providing methods to modify the channel and interact with pinned messages.
]=]
local DiscordMediaChannel = {}

DiscordMediaChannel.Prototype = {}
DiscordMediaChannel.Interface = {}

DiscordMediaChannel.Prototype.type = "DiscordMediaChannel"

--[=[
	Create a new thread inside of a Media channel.
	
	@method createThreadAsync
	@param name string
	@param message MessageBuilder
	@param appliedTags { string }?
	@param autoArchiveDuration number?
	@param rateLimitPerUser number?
	@within Objects.DiscordMediaChannel
	@return Future<unknown>
]=]
function DiscordMediaChannel.Prototype.createThreadAsync(
	self: DiscordMediaChannel,
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
	@within Objects.DiscordMediaChannel
	@return Future<unknown> -- A future that resolves when the modifications are complete.
]=]
function DiscordMediaChannel.Prototype.modifyAsync(self: DiscordMediaChannel, channelSchema)
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
	@within Objects.DiscordMediaChannel
	@return Future<{[number]: DiscordMessage}> -- A future that resolves to an array of pinned messages.
]=]
function DiscordMediaChannel.Prototype.getPinnedMessagesAsync(self: DiscordMediaChannel)
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
	Creates a new instance of DiscordMediaChannel.
	
	@function new
	@param discordClient any -- The Discord client instance.
	@param channelData table -- The data for the channel to be created.
	@within Objects.DiscordMediaChannel
	@return DiscordMediaChannel -- A new instance of DiscordMediaChannel.
]=]
function DiscordMediaChannel.Interface.new(
	discordClient: any,
	channelData: {
		id: string,
		recipients: { unknown },
	}
): DiscordMediaChannel
	local self = discordClient.discordCache:getDataOr(CacheType.DiscordMediaChannel, channelData.id, function()
		return Construct({
			id = channelData.id,

			discordClient = discordClient,
		}, DiscordMediaChannel.Prototype)
	end)

	if channelData then
		for index, value in channelData do
			self[index] = value
		end
	end

	return self
end

export type DiscordMediaChannel = typeof(DiscordMediaChannel.Prototype) & {
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

return DiscordMediaChannel.Interface
