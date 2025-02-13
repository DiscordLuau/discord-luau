--[[
	Guild Behaviour, responsible for implementing the various properties, and methods for a guild channels.
]]

local apiTypes = require("../../../lune_packages/api_types")
local stdPolyfills = require("../../../lune_packages/std_polyfills")
local future = require("../../../luau_packages/future")
local rest = require("../../../lune_packages/rest")
local state = require("../../../lune_packages/state")
local builders = require("../../../lune_packages/builders")

local overwrite = require("../overwrite")
local invite = require("../../guild/invite")
local threadMember = require("../../threadMember")

local GuildBehaviour = {}

GuildBehaviour.Interface = {}
GuildBehaviour.Prototype = {}

--[[
	Sets the position of the channel in the guild's channel list.
]]
function GuildBehaviour.Prototype.setPositionAsync<T>(self: Channel<T>, position: number)
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

--[[
	Sets the parent category of the channel and optionally syncs permissions with the parent.
]]
function GuildBehaviour.Prototype.setParentAsync<T>(self: Channel<T>, parentId: string, syncPermissions: boolean?)
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

--[[
	Sets the permissions for a role or member in the channel.
]]
function GuildBehaviour.Prototype.setPermissionsAsync<T>(
	self: Channel<T>,
	type: apiTypes.OverwriteType,
	overwriteId: string,
	allowedPermissions: builders.permissionJSON,
	denyPermissions: builders.permissionJSON,
	auditLogReason: string?
)
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

--[[
	Deletes a permission overwrite for a role or member in the channel.
]]
function GuildBehaviour.Prototype.deletePermissionAsync<T>(
	self: Channel<T>,
	type: apiTypes.OverwriteType,
	overwriteId: string,
	reason: string?
)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.channel.deleteChannelPermissionAsync(request, self.guildId, overwriteId, reason):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return nil
	end) :: future.FutureLike<string, nil>
end

--[[
	Gets a list of all invites for the channel.
]]
function GuildBehaviour.Prototype.getInvitesAsync<T>(self: Channel<T>)
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

--[[
	Creates a new invite for the channel.
]]
function GuildBehaviour.Prototype.createInviteAsync<T>(self: Channel<T>, json: builders.inviteJSON, reason: string?)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.channel.createChannelInviteAsync(request, self.id, json, reason):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return invite.new(self.state, response:unwrapOk())
	end) :: future.FutureLike<string, invite.Invite>
end

--[[
	Lists all public archived threads in the channel. Returns thread and member information.
]]
function GuildBehaviour.Prototype.listPublicArchivedThreadsAsync<T>(
	self: Channel<T>,
	before: stdPolyfills.DateTime?,
	limit: number?
)
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

--[[
	Lists all private archived threads in the channel. Returns thread and member information.
]]
function GuildBehaviour.Prototype.listPrivateArchivedThreadsAsync<T>(
	self: Channel<T>,
	before: stdPolyfills.DateTime?,
	limit: number?
)
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

--[[
	Lists all private archived threads that the current user has joined. Returns thread and member information.
]]
function GuildBehaviour.Prototype.listJoinedPrivateArchivedThreadsAsync<T>(
	self: Channel<T>,
	before: stdPolyfills.DateTime?,
	limit: number?
)
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

--[[
	Sets the name of the channel.
]]
function GuildBehaviour.Prototype.setNameAsync<T>(self: Channel<T>, groupName: string)
	return self:modifyAsync({
		name = groupName,
	}) :: future.FutureLike<string, Channel<T>>
end

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
