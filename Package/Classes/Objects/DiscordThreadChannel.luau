local Construct = require("../../Utils/Construct")

local CacheType = require("../../Enums/CacheType")
local DiscordEndpoints = require("../../Data/DiscordEndpoints")

local Future = require("../../Vendor/Future")

local DiscordMessage = require("../Objects/DiscordMessage")
local DiscordGuildMember = require("../Objects/DiscordGuildMember")

--[=[
	@class Objects.DiscordThreadChannel

	DiscordThreadChannel represents a thread channel in a Discord server, providing methods to modify the channel and interact with pinned messages.
]=]
local DiscordThreadChannel = {}

DiscordThreadChannel.Prototype = {}
DiscordThreadChannel.Interface = {}

DiscordThreadChannel.Prototype.type = "DiscordThreadChannel"

--[=[
	Joins the current discord bot into the thread
	
	@method joinThreadAsync
	@within Objects.DiscordThreadChannel
	@return Future<unknown> -- A future the bot has joined the thread channel
]=]
function DiscordThreadChannel.Prototype.joinThreadAsync(self: DiscordThreadChannel)
	return Future.try(function()
		return self.discordClient.discordGateway:putAsync(string.format(DiscordEndpoints.BotJoinThreadChannel, self.id), { }):await()
	end)
end

--[=[
	Adds the passed member to the thread channel
	
	@method addMemberToThreadAsync
	@param userId string
	@within Objects.DiscordThreadChannel
	@return Future<unknown> -- A future the bot has joined the thread channel
]=]
function DiscordThreadChannel.Prototype.addMemberToThreadAsync(self: DiscordThreadChannel, userId: string)
	return Future.try(function()
		return self.discordClient.discordGateway:putAsync(string.format(DiscordEndpoints.BotAddMemberToThreadChannel, self.id, userId), { }):await()
	end)
end

--[=[
	Leaves the thread channel if the discord bot is in the channel.
	
	@method leaveThreadAsync
	@within Objects.DiscordThreadChannel
	@return Future<unknown> -- A future the bot has joined the thread channel
]=]
function DiscordThreadChannel.Prototype.leaveThreadAsync(self: DiscordThreadChannel)
	return Future.try(function()
		return self.discordClient.discordGateway:deleteAsync(string.format(DiscordEndpoints.BotLeaveThreadChannel, self.id), { }):await()
	end)
end

--[=[
	Removes the passed user id from the current thread channel
	
	@method removeMemberFromThreadAsync
	@param userId string
	@within Objects.DiscordThreadChannel
	@return Future<unknown> -- A future the bot has joined the thread channel
]=]
function DiscordThreadChannel.Prototype.removeMemberFromThreadAsync(self: DiscordThreadChannel, userId: string)
	return Future.try(function()
		return self.discordClient.discordGateway:putAsync(string.format(DiscordEndpoints.BotRemoveMemberFromThreadChannel, self.id, userId), { }):await()
	end)
end

--[=[
	Returns a list of members that are active in the current thread channel
	
	@method removeMemberFromThreadAsync
	@param userId string
	@within Objects.DiscordThreadChannel
	@return Future<{ DiscordGuildMember }> -- A future the bot has joined the thread channel
]=]
function DiscordThreadChannel.Prototype.getThreadMembersAsync(self: DiscordThreadChannel)
	return Future.try(function()
		local memberObjects = self.discordClient.discordGateway:getAsync(string.format(DiscordEndpoints.BotGetThreadMembers, self.id), { }):await()

		for key, memberObject in memberObjects do
			memberObjects[key] = DiscordGuildMember.new(self.discordClient, memberObject.user.id, self.guildId, memberObject)
		end

		return memberObjects
	end)
end

--[=[
	Modifies the thread channel settings asynchronously.
	
	@method modifyAsync
	@param channelSchema DiscordTextChannelSchema -- The schema containing the modifications to be applied.
	@within Objects.DiscordThreadChannel
	@return Future<unknown> -- A future that resolves when the modifications are complete.
]=]
function DiscordThreadChannel.Prototype.modifyAsync(self: DiscordThreadChannel, channelSchema)
	return Future.try(function()
		
	end)
end

--[=[
	Retrieves the pinned messages in the thread channel asynchronously.
	
	@method getPinnedMessagesAsync
	@within Objects.DiscordThreadChannel
	@return Future<{[number]: DiscordMessage}> -- A future that resolves to an array of pinned messages.
]=]
function DiscordThreadChannel.Prototype.getPinnedMessagesAsync(self: DiscordThreadChannel)
	return Future.try(function()
		local messages = self.discordClient.discordGateway:getAsync(string.format(DiscordEndpoints.BotGetPinnedMessages, self.id), { }):await()

		for index, messageData in messages do
			messages[index] = DiscordMessage.new(self.discordClient, messageData)
		end

		return messages
	end)
end

--[=[
	Creates a new instance of DiscordThreadChannel.
	
	@function new
	@param discordClient any -- The Discord client instance.
	@param channelData table -- The data for the channel to be created.
	@within Objects.DiscordThreadChannel
	@return DiscordThreadChannel -- A new instance of DiscordThreadChannel.
]=]
function DiscordThreadChannel.Interface.new(discordClient: any, channelData: {
	id: string,
	recipients: { unknown },
}): DiscordThreadChannel
	local self = discordClient.discordCache:getDataOr(CacheType.DiscordThreadChannel, channelData.id, function()
		return Construct({
			id = channelData.id,
	
			discordClient = discordClient
		}, DiscordThreadChannel.Prototype)
	end)

	if channelData then
		for index, value in channelData do
			self[index] = value
		end
	end

	return self
end

export type DiscordThreadChannel = typeof(DiscordThreadChannel.Prototype) & {
	discordClient: any,

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

return DiscordThreadChannel.Interface
