--[=[
	@class Classes.Channels.GuildBehaviour
	@__index Prototype

	Behaviour class that implements the properties and methods specific to guild channels in Discord.
	This behaviour is inherited by guild channel classes to provide guild-specific functionality.

	Guild behaviours include:
	- Managing channel positions and categories
	- Handling permission overwrites
	- Managing invites
	- Managing thread archives
	- Handling guild-specific channel properties
]=]

--[=[
	@within Classes.Channels.GuildBehaviour
	@prop permissionOverwrites { Classes.Channels.Overwrite }
	The permission overwrites for the channel.
]=]

--[=[
	@within Classes.Channels.GuildBehaviour
	@prop nsfw boolean
	Whether the channel is marked as NSFW (Not Safe For Work).
]=]

--[=[
	@within Classes.Channels.GuildBehaviour
	@prop topic string?
	The topic of the channel.
]=]

--[=[
	@within Classes.Channels.GuildBehaviour
	@prop guildId string
	The ID of the guild this channel belongs to.
]=]

--[=[
	@within Classes.Channels.GuildBehaviour
	@prop position number
	The position of the channel in the guild's channel list.
]=]

--[=[
	@within Classes.Channels.GuildBehaviour
	@prop parentId string?
	The ID of the parent category channel, if this channel is in a category.
]=]

--[=[
	@within Classes.Channels.GuildBehaviour
	@prop permissions number
	The computed permissions for the current user in this channel.
]=]

--[=[
	@within Classes.Channels.GuildBehaviour
	@prop defaultThreadRateLimitPerUser number
	The default rate limit per user for threads in this channel.
]=]

--[=[
	@within Classes.Channels.GuildBehaviour
	@prop defaultAutoArchiveDuration number
	The default duration after which threads are automatically archived.
]=]

local apiTypes = require("../../../luau_packages/api_types")
local stdPolyfills = require("../../../luau_packages/std_polyfills")
local future = require("../../../luau_packages/future")
local rest = require("../../../luau_packages/rest")
local state = require("../../../luau_packages/state")
local builders = require("../../../luau_packages/builders")

local overwrite = require("../overwrite")
local invite = require("../../guild/invite")
local threadMember = require("../../threadMember")

local GuildBehaviour = {}

GuildBehaviour.Interface = {}
GuildBehaviour.Prototype = {}

--[=[
	@within Classes.Channels.GuildBehaviour
	Sets the position of the channel in the guild's channel list.
]=]
function GuildBehaviour.Prototype.setPositionAsync<T>(self: Channel<T>, position: number): future.FutureLike<string, nil>
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.guild
			.modifyGuildChannelPositionsAsync(request, self.guildId, {
				{
					id = self.id,
					position = position,
				},
			})
			:await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return nil
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Classes.Channels.GuildBehaviour
	Sets the parent category of the channel and optionally syncs permissions with the parent.
]=]
function GuildBehaviour.Prototype.setParentAsync<T>(self: Channel<T>, parentId: string, syncPermissions: boolean?): future.FutureLike<string, nil>
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.guild
			.modifyGuildChannelPositionsAsync(request, self.guildId, {
				{
					id = self.id,
					lock_permissions = syncPermissions,
					parent_id = parentId,
				},
			})
			:await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return nil
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Classes.Channels.GuildBehaviour
	Sets the permissions for a role or member in the channel.
]=]
function GuildBehaviour.Prototype.setPermissionsAsync<T>(
	self: Channel<T>,
	type: apiTypes.OverwriteType,
	overwriteId: string,
	allowedPermissions: builders.permissionJSON,
	denyPermissions: builders.permissionJSON,
	auditLogReason: string?
): future.FutureLike<string, nil>
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.channel
			.editChannelPermissionsAsync(request, self.id, overwriteId, {
				type = apiTypes.guild.OverwriteType[type],
				allow = allowedPermissions,
				deny = denyPermissions,
			}, auditLogReason)
			:await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return nil
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Classes.Channels.GuildBehaviour
	Deletes a permission overwrite for a role or member in the channel.
]=]
function GuildBehaviour.Prototype.deletePermissionAsync<T>(
	self: Channel<T>,
	type: apiTypes.OverwriteType,
	overwriteId: string,
	reason: string?
): future.FutureLike<string, nil>
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.channel.deleteChannelPermissionAsync(request, self.guildId, overwriteId, reason):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return nil
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Classes.Channels.GuildBehaviour
	Gets a list of all invites for the channel.
]=]
function GuildBehaviour.Prototype.getInvitesAsync<T>(self: Channel<T>): future.FutureLike<string, { invite.Invite }>
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.channel.getChannelInvitesAsync(request, self.id):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		local invites = {}

		for _, inviteData in response:unwrapOk() do
			table.insert(invites, invite.new(self.state, inviteData))
		end

		return invites
	end) :: future.FutureLike<string, { invite.Invite }>
end

--[=[
	@within Classes.Channels.GuildBehaviour
	Creates a new invite for the channel.
]=]
function GuildBehaviour.Prototype.createInviteAsync<T>(self: Channel<T>, json: builders.inviteJSON, reason: string?): future.FutureLike<string, invite.Invite>
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.channel.createChannelInviteAsync(request, self.id, json, reason):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return invite.new(self.state, response:unwrapOk())
	end) :: future.FutureLike<string, invite.Invite>
end

--[=[
	@within Classes.Channels.GuildBehaviour
	Lists all public archived threads in the channel. Returns thread and member information.
]=]
function GuildBehaviour.Prototype.listPublicArchivedThreadsAsync<T>(
	self: Channel<T>,
	before: stdPolyfills.DateTime?,
	limit: number?
): future.FutureLike<string, { threads: { apiTypes.Snowflake }, members: { threadMember.ThreadMember }, hasMore: boolean }>
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.channel
			.listPublicArchivedThreadsAsync(request, self.id, {
				before = before and before:toIsoDate() or nil,
				limit = limit,
			})
			:await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		local data = response:unwrapOk()
		local returnedValue = {
			threads = {},
			members = {},
			hasMore = data.has_more,
		}

		for _, threadData in next, data.threads do
			table.insert(returnedValue.threads, threadData.id)
		end

		for _, threadMemberData in next, data.members do
			local member = threadMember.new(self.state, self.guildId, threadMemberData)

			table.insert(returnedValue.members, member)
		end

		return returnedValue :: any
	end) :: future.FutureLike<string, {
		threads: { apiTypes.Snowflake },
		members: { threadMember.ThreadMember },
		hasMore: boolean,
	}>
end

--[=[
	@within Classes.Channels.GuildBehaviour
	Lists all private archived threads in the channel. Returns thread and member information.
]=]
function GuildBehaviour.Prototype.listPrivateArchivedThreadsAsync<T>(
	self: Channel<T>,
	before: stdPolyfills.DateTime?,
	limit: number?
): future.FutureLike<string, { threads: { apiTypes.Snowflake }, members: { threadMember.ThreadMember }, hasMore: boolean }>
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.channel
			.listPrivateArchivedThreadsAsync(request, self.id, {
				before = before and before:toIsoDate() or nil,
				limit = limit,
			})
			:await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		local data = response:unwrapOk()
		local returnedValue = {
			threads = {},
			members = {},
			hasMore = data.has_more,
		}

		for _, threadData in next, data.threads do
			table.insert(returnedValue.threads, threadData.id)
		end

		for _, threadMemberData in next, data.members do
			local member = threadMember.new(self.state, self.guildId, threadMemberData)

			table.insert(returnedValue.members, member)
		end

		return returnedValue :: any
	end) :: future.FutureLike<string, {
		threads: { apiTypes.Snowflake },
		members: { threadMember.ThreadMember },
		hasMore: boolean,
	}>
end

--[=[
	@within Classes.Channels.GuildBehaviour
	Lists all private archived threads that the current user has joined. Returns thread and member information.
]=]
function GuildBehaviour.Prototype.listJoinedPrivateArchivedThreadsAsync<T>(
	self: Channel<T>,
	before: stdPolyfills.DateTime?,
	limit: number?
): future.FutureLike<string, { threads: { apiTypes.Snowflake }, members: { threadMember.ThreadMember }, hasMore: boolean }>
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.channel
			.listJoinedPrivateArchivedThreadsAsync(request, self.id, {
				before = before and before:toIsoDate() or nil,
				limit = limit,
			})
			:await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		local data = response:unwrapOk()
		local returnedValue = {
			threads = {},
			members = {},
			hasMore = data.has_more,
		}

		for _, threadData in next, data.threads do
			table.insert(returnedValue.threads, threadData.id)
		end

		for _, threadMemberData in next, data.members do
			local member = threadMember.new(self.state, self.guildId, threadMemberData)

			table.insert(returnedValue.members, member)
		end

		return returnedValue :: any
	end) :: future.FutureLike<string, {
		threads: { apiTypes.Snowflake },
		members: { threadMember.ThreadMember },
		hasMore: boolean,
	}>
end

--[=[
	@within Classes.Channels.GuildBehaviour
	Sets the name of the channel.
]=]
function GuildBehaviour.Prototype.setNameAsync<T>(self: Channel<T>, groupName: string): future.FutureLike<string, Channel<T>>
	return self:modifyAsync({
		name = groupName,
	}) :: future.FutureLike<string, Channel<T>>
end

--[=[
	@within Classes.Channels.GuildBehaviour
	@private

	Inherits properties from the channel data into the class instance.
	This is typically called during object creation or updates.
]=]
function GuildBehaviour.Interface.inheritProperties(class: any, channelData: apiTypes.ChannelObject)
	local permissionOverwriteArray = {}

	--fixme: requires 'next' otherwise type system borks.
	for _, overwriteData in next, channelData.permission_overwrites or {} do
		table.insert(permissionOverwriteArray, overwrite.new(overwriteData))
	end

	class.permissionOverwrites = permissionOverwriteArray

	class.nsfw = channelData.nsfw

	class.topic = channelData.topic

	class.guildId = channelData.guild_id

	class.position = channelData.position

	class.parentId = channelData.parent_id

	class.permissions = channelData.permissions

	class.defaultThreadRateLimitPerUser = channelData.rate_limit_per_user

	class.defaultAutoArchiveDuration = channelData.default_auto_archive_duration
end

--[=[
	@within Classes.Channels.GuildBehaviour
	@private

	Inherits methods from the GuildBehaviour prototype into the class instance.
	This is typically called during object creation or updates.
]=]
function GuildBehaviour.Interface.inheritMethods(class: any)
	for key, value in GuildBehaviour.Prototype do
		class[key] = value
	end
end

type Channel<T> = T & GuildBehaviour & {
	state: state.State,
	id: string,

	modifyAsync: any,

	sync: (...any) -> (),
}

export type GuildBehaviourMethods = typeof(GuildBehaviour.Prototype)
export type GuildBehaviourProperties = {
	permissionOverwrites: { overwrite.Overwrite },
	nsfw: boolean,
	topic: string?,
	guildId: string,
	position: number,
	parentId: string?,
	permissions: number,
	defaultThreadRateLimitPerUser: number,
	defaultAutoArchiveDuration: number,
}

export type GuildBehaviour = GuildBehaviourMethods & GuildBehaviourProperties

return GuildBehaviour.Interface
