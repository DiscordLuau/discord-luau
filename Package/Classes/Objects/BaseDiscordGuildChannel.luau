local Construct = require("../../Utils/Construct")
local Extend = require("../../Utils/Extend")

local DiscordEndpoints = require("../../Data/DiscordEndpoints")

local Future = require("../../Vendor/Future")

local CacheType = require("../../Enums/CacheType")

local BaseDiscordChannel = require("BaseDiscordChannel")
local DiscordInvite = require("DiscordInvite")

local Resolvable = require("../Network/Resolvable")
local ResolvableType = require("../../Enums/ResolveableType")

local PermissionsBuilder = require("../Builders/PermissionsBuilder")
local ChannelBuilder = require("../Builders/ChannelBuilder")

local Datetime = require("../../Std/Datetime")

--[=[
	@class Objects.BaseDiscordGuildChannel

	Represents a base object for any/all guild channels.
]=]
local BaseDiscordGuildChannel = {}

BaseDiscordGuildChannel.Prototype = {}
BaseDiscordGuildChannel.Interface = {}

BaseDiscordGuildChannel.Prototype.type = "BaseDiscordGuildChannel"

--[=[
	set overwrites for a specific role permissions for this channel in a discord guild.

	@method overwriteRolePermissionsAsync
	@param roleId string
	@param allowedPermissions PermissionsBuilder.PermissionsBuilder
	@param disallowedPermissions PermissionsBuilder.PermissionsBuilder
	@within Objects.BaseDiscordGuildChannel
	@return Future
]=]
function BaseDiscordGuildChannel.Prototype.overwriteRolePermissionsAsync(
	self: BaseDiscordGuildChannel,
	roleId: string,
	allowedPermissions: PermissionsBuilder.PermissionsBuilder,
	disallowedPermissions: PermissionsBuilder.PermissionsBuilder
)
	return Future.try(function()
		return self.discordClient.discordGateway
			:putAsync(
				string.format(DiscordEndpoints.BotEditChannelPermissions, self.id, roleId),
				Resolvable.new(ResolvableType.JSON, {
					allow = allowedPermissions:getValue(),
					deny = disallowedPermissions:getValue(),
					type = 0,
				})
			)
			:await()
	end)
end

--[=[
	set overwrites for a specific members permissions for this channel in a discord guild.

	@method overwriteMemberPermissionssync
	@param memberId string
	@param allowedPermissions PermissionsBuilder.PermissionsBuilder
	@param disallowedPermissions PermissionsBuilder.PermissionsBuilder
	@within Objects.BaseDiscordGuildChannel
	@return Future
]=]
function BaseDiscordGuildChannel.Prototype.overwriteMemberPermissionssync(
	self: BaseDiscordGuildChannel,
	memberId: string,
	allowedPermissions: PermissionsBuilder.PermissionsBuilder,
	disallowedPermissions: PermissionsBuilder.PermissionsBuilder
)
	return Future.try(function()
		return self.discordClient.discordGateway
			:putAsync(
				string.format(DiscordEndpoints.BotEditChannelPermissions, self.id, memberId),
				Resolvable.new(ResolvableType.JSON, {
					allow = allowedPermissions:getValue(),
					deny = disallowedPermissions:getValue(),
					type = 1,
				})
			)
			:await()
	end)
end

--[=[
	deletes overwritten permissions for the given id, the given id must be either a role id or a user id

	@method overwriteMemberPermissionssync
	@param roleIdOrUserId string
	@within Objects.BaseDiscordGuildChannel
	@return Future
]=]
function BaseDiscordGuildChannel.Prototype.deletePermissionOverwriteAsync(
	self: BaseDiscordGuildChannel,
	roleIdOrUserId: string
)
	return Future.try(function()
		return self.discordClient.discordGateway
			:deleteAsync(string.format(DiscordEndpoints.BotDeleteChannelPermission, self.id, roleIdOrUserId))
			:await()
	end)
end

--[=[
	Gets the invites for the channel asynchronously.

	@method getInvitesAsync
	@within Objects.BaseDiscordGuildChannel
	@return Future
]=]
function BaseDiscordGuildChannel.Prototype.getInvitesAsync(self: BaseDiscordGuildChannel)
	return Future.try(function()
		local invites =
			self.discordClient.discordGateway:getAsync(string.format(DiscordEndpoints.BotGetInvites, self.id)):await()

		for index, inviteData in invites do
			invites[index] = DiscordInvite.new(self.discordClient, inviteData)
		end

		return invites
	end)
end

--[=[
	Creates an invite for the channel asynchronously.

	@method createInviteAsync
	@param maxAge number? -- The maximum age of the invite in seconds.
	@param maxUses number? -- The maximum number of uses for the invite.
	@param temporary boolean? -- Whether the invite grants temporary membership.
	@within Objects.BaseDiscordGuildChannel
	@return Future
]=]
function BaseDiscordGuildChannel.Prototype.createInviteAsync(
	self: BaseDiscordGuildChannel,
	maxAge: number?,
	maxUses: number?,
	temporary: boolean?
)
	return Future.try(function()
		local inviteData = self.discordClient.discordGateway
			:postAsync(
				string.format(DiscordEndpoints.BotGetInvites, self.id),
				Resolvable.new(ResolvableType.JSON, {
					max_age = maxAge,
					max_uses = maxUses,
					temporary = temporary,
				})
			)
			:await()

		return DiscordInvite.new(self.discordClient, inviteData)
	end)
end

--[=[
	Sets the position of the channel asynchronously.

	@method setPositionAsync
	@param position number -- The new position of the channel.
	@param parentId string? -- The ID of the new parent category.
	@param syncPermissions boolean? -- Whether to sync permissions with the new parent.
	@within Objects.BaseDiscordGuildChannel
	@return Future
]=]
function BaseDiscordGuildChannel.Prototype.setPositionAsync(
	self: BaseDiscordGuildChannel,
	position: number,
	parentId: string?,
	syncPermissions: boolean?
)
	return Future.try(function()
		return self.discordClient.discordGateway
			:patchAsync(
				string.format(DiscordEndpoints.BotModifyGuildChannelPosition, self.id),
				Resolvable.new(ResolvableType.JSON, {
					id = self.id,
					position = position,
					parent_id = parentId,
					lock_permissions = syncPermissions,
				})
			)
			:await()
	end)
end

--[=[
	Modifies the thread channel settings asynchronously.
	
	@method modifyAsync
	@param channelBuilder ChannelBuilder.ChannelBuilder
	@within Objects.BaseDiscordGuildChannel
	@return Future<unknown>
]=]
function BaseDiscordGuildChannel.Prototype.modifyAsync(
	self: BaseDiscordGuildChannel,
	channelBuilder: ChannelBuilder.ChannelBuilder
)
	return Future.try(function()
		return self.discordClient.discordGateway
			:patchAsync(string.format(DiscordEndpoints.BotModifyChannel, self.id), channelBuilder:toPayloadObject())
			:await()
	end)
end

--[=[
	Gets all archived public threads in the guild channel asynchronously.

	@method getPublicArchivedThreadsAsync
	@param epoch number?
	@pram limit number?
	@return Future<{ number }>
	@within Objects.BaseDiscordGuildChannel
]=]
function BaseDiscordGuildChannel.Prototype.getPublicArchivedThreadsAsync(
	self: BaseDiscordGuildChannel,
	epoch: number?,
	limit: number?
)
	return Future.try(function()
		local rawThreadData = self.discordClient.discordGateway
			:getAsync(
				string.format(
					DiscordEndpoints.BotListPublicArchivedThreads,
					self.id,
					(epoch and Datetime.fromUnixTimestamp(epoch) or Datetime.now()):toIsoDate(),
					limit or 100
				)
			)
			:await()

		local threads: { string } = {}

		for _, threadObject in rawThreadData.threads do
			table.insert(threads, threadObject.id)
		end

		return threads
	end)
end

--[=[
	Gets all archived private threads in the guild channel asynchronously.

	@method getPrivateArchivedThreadsAsync
	@param epoch number?
	@pram limit number?
	@return Future<{ number }>
	@within Objects.BaseDiscordGuildChannel
]=]
function BaseDiscordGuildChannel.Prototype.getPrivateArchivedThreadsAsync(
	self: BaseDiscordGuildChannel,
	epoch: number?,
	limit: number?
)
	return Future.try(function()
		local rawThreadData = self.discordClient.discordGateway
			:getAsync(
				string.format(
					DiscordEndpoints.BotListPrivateArchivedThreads,
					self.id,
					(epoch and Datetime.fromUnixTimestamp(epoch) or Datetime.now()):toIsoDate(),
					limit or 100
				)
			)
			:await()

		local threads: { string } = {}

		for _, threadObject in rawThreadData.threads do
			table.insert(threads, threadObject.id)
		end

		return threads
	end)
end

--[=[
	Gets all archived private threads that the bot is a member of, in the guild channel asynchronously.

	@method getJoinedPrivateArchivedThreads
	@param epoch number?
	@pram limit number?
	@return Future<{ number }>
	@within Objects.BaseDiscordGuildChannel
]=]
function BaseDiscordGuildChannel.Prototype.getJoinedPrivateArchivedThreads(
	self: BaseDiscordGuildChannel,
	epoch: number?,
	limit: number?
)
	return Future.try(function()
		local rawThreadData = self.discordClient.discordGateway
			:getAsync(
				string.format(
					DiscordEndpoints.BotListJoinedPrivateArchivedThreads,
					self.id,
					(epoch and Datetime.fromUnixTimestamp(epoch) or Datetime.now()):toIsoDate(),
					limit or 100
				)
			)
			:await()

		local threads: { string } = {}

		for _, threadObject in rawThreadData.threads do
			table.insert(threads, threadObject.id)
		end

		return threads
	end)
end

function BaseDiscordGuildChannel.Interface.new(
	discordClient,
	channelData: {
		id: string,
		guildId: string?,
	}
)
	local channelObject = Construct({
		discordClient = discordClient,
	}, BaseDiscordGuildChannel.Prototype)

	return Extend(channelObject, BaseDiscordChannel.new(discordClient, channelData))
end

export type BaseDiscordGuildChannel = BaseDiscordChannel.BaseDiscordChannel & typeof(BaseDiscordGuildChannel.Prototype) & {
	guildId: string,
}

return BaseDiscordGuildChannel.Interface
