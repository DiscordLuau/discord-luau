local Future = require("@Vendor/Future")

local Construct = require("@Utils/Construct")
local Extend = require("@Utils/Extend")

local DiscordGuildMember = require("@Objects/DiscordGuildMember")
local BaseGuildTextChannel = require("@Objects/BaseGuildTextChannel")
local DiscordEmoji = require("@Objects/DiscordEmoji")

local DiscordEndpoints = require("@Data/DiscordEndpoints")

--[=[
	@class Objects.BaseGuildThread

	A base discord Thread channel, all discord threads extend from.

	@tag inherit Objects.BaseGuildTextChannel
]=]
local BaseGuildThread = {}

BaseGuildThread.Prototype = {}
BaseGuildThread.Interface = {}

BaseGuildThread.Prototype.type = "BaseGuildThread"

--[=[
	Joins the current discord bot into the thread
	
	@method joinThreadAsync
	@within Objects.BaseGuildThread
	@return Vendor.Future<unknown> -- A future the bot has joined the thread channel
]=]
function BaseGuildThread.Prototype.joinThreadAsync(self: BaseGuildThread)
	return Future.try(function()
		return self.discordClient.discordGateway
			:putAsync(string.format(DiscordEndpoints.BotJoinThreadChannel, self.id))
			:await()
	end)
end

--[=[
	Adds the passed member to the thread channel
	
	@method addMemberToThreadAsync
	@param userId string
	@within Objects.BaseGuildThread
	@return Vendor.Future<unknown> -- A future the bot has joined the thread channel
]=]
function BaseGuildThread.Prototype.addMemberToThreadAsync(self: BaseGuildThread, userId: string)
	return Future.try(function()
		return self.discordClient.discordGateway
			:putAsync(string.format(DiscordEndpoints.BotAddMemberToThreadChannel, self.id, userId))
			:await()
	end)
end

--[=[
	Leaves the thread channel if the discord bot is in the channel.
	
	@method leaveThreadAsync
	@within Objects.BaseGuildThread
	@return Vendor.Future<unknown> -- A future the bot has joined the thread channel
]=]
function BaseGuildThread.Prototype.leaveThreadAsync(self: BaseGuildThread)
	return Future.try(function()
		return self.discordClient.discordGateway
			:deleteAsync(string.format(DiscordEndpoints.BotLeaveThreadChannel, self.id))
			:await()
	end)
end

--[=[
	Removes the passed user id from the current thread channel
	
	@method removeMemberFromThreadAsync
	@param userId string
	@within Objects.BaseGuildThread
	@return Vendor.Future<unknown> -- A future the bot has joined the thread channel
]=]
function BaseGuildThread.Prototype.removeMemberFromThreadAsync(self: BaseGuildThread, userId: string)
	return Future.try(function()
		return self.discordClient.discordGateway
			:putAsync(string.format(DiscordEndpoints.BotRemoveMemberFromThreadChannel, self.id, userId))
			:await()
	end)
end

--[=[
	Returns a list of members that are active in the current thread channel
	
	@method getThreadMemberAsync
	@param userId string
	@within Objects.BaseGuildThread
	@return Vendor.Future<{ DiscordGuildMember }> -- A future the bot has joined the thread channel
]=]
function BaseGuildThread.Prototype.getThreadMemberAsync(self: BaseGuildThread, userId: string)
	return Future.try(function()
		local memberObject = self.discordClient.discordGateway
			:getAsync(string.format(DiscordEndpoints.BotGetThreadMember, self.id, userId))
			:await()

		memberObject = DiscordGuildMember.new(self.discordClient, memberObject.userId, self.guildId, memberObject)

		return memberObject
	end)
end

--[=[
	Returns a list of members that are active in the current thread channel
	
	@method removeMemberFromThreadAsync
	@param userId string
	@within Objects.BaseGuildThread
	@return Vendor.Future<{ DiscordGuildMember }> -- A future the bot has joined the thread channel
]=]
function BaseGuildThread.Prototype.getThreadMembersAsync(self: BaseGuildThread)
	return Future.try(function()
		local memberObjects = self.discordClient.discordGateway
			:getAsync(string.format(DiscordEndpoints.BotGetThreadMembers, self.id))
			:await()

		for key, memberObject in memberObjects do
			memberObjects[key] =
				DiscordGuildMember.new(self.discordClient, memberObject.user.id, self.guildId, memberObject)
		end

		return memberObjects
	end)
end

function BaseGuildThread.Interface.new(
	discordClient,
	channelData: {
		id: string,
		guildId: string,

		[string]: any,
	}
)
	local channelObject = Construct({
		discordClient = discordClient,
	}, BaseGuildThread.Prototype)

	if channelData.defaultReactionEmoji then
		channelData.defaultReactionEmoji = DiscordEmoji.new(discordClient, channelData.defaultReactionEmoji)
	end

	for index, value in channelData do
		(channelObject :: {})[index] = value
	end

	return Extend(channelObject, BaseGuildTextChannel.new(discordClient, channelData))
end

export type BaseGuildThread = BaseGuildTextChannel.BaseGuildTextChannel & typeof(BaseGuildThread.Prototype) & {
	discordClient: any,

	ownerId: string,

	messageCount: number,
	memberCount: number,
	totalMessageSent: number?,

	threadMetadata: {
		archived: boolean,
		autoArchiveDuration: number,
		archiveTimestamp: string,
		locked: boolean,
		invitable: boolean?,
		createTimestamp: string?,
	},

	availableTags: {
		{
			id: string,
			name: string,
			moderated: boolean,
			emojiId: string?,
			emojiName: string?,
		}
	},

	appliedTags: { string },
	defaultReactionEmoji: DiscordEmoji.DiscordEmoji,
}

return BaseGuildThread.Interface
