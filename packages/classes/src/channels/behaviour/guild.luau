--[[
	Guild Behaviour, responsible for implementing the various properties, and methods for a guild channels.
]]

local datetime = require("@std-polyfills/datetime")

local future = require("@vendor/future")

local apiTypes = require("@api-types/apiTypes")
local guildTypes = require("@api-types/guild")

local channelRest = require("@rest/channel")
local guildRest = require("@rest/guild")

local overwrite = require("@classes/channels/overwrite")
local state = require("@classes/state")
local invite = require("@classes/guild/invite")
local threadMember = require("@classes/threadMember")

local inviteBuilder = require("@builders/invite")
local permissionBuilder = require("@builders/permission")
local channelBuilder = require("@builders/channel")

local GuildBehaviour = {}

GuildBehaviour.Interface = {}
GuildBehaviour.Prototype = {}

--[[
	Sets the position of the channel in the guild's channel list.
]]
function GuildBehaviour.Prototype.setPositionAsync<T>(self: Channel<T>, position: number): future.Future<nil>
	return future.new(function()
		local request = self.state.rest:newRequest()

		local status, response = guildRest
			.modifyGuildChannelPositionsAsync(request, self.guildId, {
				id = self.id,
				position = position,
			})
			:await()

		assert(status == "Fulfilled", tostring(response))

		return nil
	end)
end

--[[
	Sets the parent category of the channel and optionally syncs permissions with the parent.
]]
function GuildBehaviour.Prototype.setParentAsync<T>(
	self: Channel<T>,
	parentId: string,
	syncPermissions: boolean?
): future.Future<nil>
	return future.new(function()
		local request = self.state.rest:newRequest()

		local status, response = guildRest
			.modifyGuildChannelPositionsAsync(request, self.guildId, {
				id = self.id,
				lock_permissions = syncPermissions,
				parent_id = parentId,
			})
			:await()

		assert(status == "Fulfilled", tostring(response))

		return nil
	end)
end

--[[
	Sets the permissions for a role or member in the channel.
]]
function GuildBehaviour.Prototype.setPermissionsAsync<T>(
	self: Channel<T>,
	type: guildTypes.OverwriteType,
	overwriteId: string,
	allowedPermissions: permissionBuilder.JSON,
	denyPermissions: permissionBuilder.JSON
): future.Future<nil>
	return future.new(function()
		local request = self.state.rest:newRequest()

		local status, response = guildRest
			.modifyGuildChannelPositionsAsync(request, self.guildId, {
				type = guildTypes.OverwriteType[type],
				id = overwriteId,
				allow = allowedPermissions,
				deny = denyPermissions,
			})
			:await()

		assert(status == "Fulfilled", tostring(response))

		return nil
	end)
end

--[[
	Deletes a permission overwrite for a role or member in the channel.
]]
function GuildBehaviour.Prototype.deletePermissionAsync<T>(
	self: Channel<T>,
	type: guildTypes.OverwriteType,
	overwriteId: string,
	reason: string?
): future.Future<nil>
	return future.new(function()
		local request = self.state.rest:newRequest()

		local status, response =
			channelRest.deleteChannelPermissionAsync(request, self.guildId, overwriteId, reason):await()

		assert(status == "Fulfilled", tostring(response))

		return nil
	end)
end

--[[
	Gets a list of all invites for the channel.
]]
function GuildBehaviour.Prototype.getInvitesAsync<T>(self: Channel<T>): future.Future<{ invite.Invite }>
	return future.new(function()
		local request = self.state.rest:newRequest()

		local status, response = channelRest.getChannelInvitesAsync(request, self.id):await()

		assert(status == "Fulfilled", tostring(response))

		local invites = {}

		for _, inviteData in response do
			table.insert(invites, invite.new(self.state, inviteData))
		end

		return invites
	end)
end

--[[
	Creates a new invite for the channel.
]]
function GuildBehaviour.Prototype.createInviteAsync<T>(
	self: Channel<T>,
	json: inviteBuilder.JSON,
	reason: string?
): future.Future<invite.Invite>
	return future.new(function()
		local request = self.state.rest:newRequest()

		local status, response = channelRest.createChannelInviteAsync(request, self.id, json, reason):await()

		assert(status == "Fulfilled", tostring(response))

		return invite.new(self.state, response)
	end)
end

--[[
	Lists all public archived threads in the channel. Returns thread and member information.
]]
function GuildBehaviour.Prototype.listPublicArchivedThreadsAsync<T>(
	self: Channel<T>,
	before: datetime.DateTime?,
	limit: number?
): future.Future<string>
	return future.new(function()
		local request = self.state.rest:newRequest()

		local status, response = channelRest
			.listPublicArchivedThreadsAsync(request, self.id, {
				before = before and before:toIsoDate() or nil,
				limit = limit,
			})
			:await()

		assert(status == "Fulfilled", tostring(response))

		local returnedValue = {
			threads = {},
			members = {},
			hasMore = response.has_more,
		}

		for _, threadData in next, response.threads do
			table.insert(returnedValue.threads, threadData.id)
		end

		for _, threadMemberData in next, response.members do
			local member = threadMember.new(self.state, self.guildId, threadMemberData)

			table.insert(returnedValue.members, member)
		end

		return returnedValue
	end)
end

--[[
	Lists all private archived threads in the channel. Returns thread and member information.
]]
function GuildBehaviour.Prototype.listPrivateArchivedThreadsAsync<T>(
	self: Channel<T>,
	before: datetime.DateTime?,
	limit: number?
): future.Future<string>
	return future.new(function()
		local request = self.state.rest:newRequest()

		local status, response = channelRest
			.listPrivateArchivedThreadsAsync(request, self.id, {
				before = before and before:toIsoDate() or nil,
				limit = limit,
			})
			:await()

		assert(status == "Fulfilled", tostring(response))

		local returnedValue = {
			threads = {},
			members = {},
			hasMore = response.has_more,
		}

		for _, threadData in next, response.threads do
			table.insert(returnedValue.threads, threadData.id)
		end

		for _, threadMemberData in next, response.members do
			local member = threadMember.new(self.state, self.guildId, threadMemberData)

			table.insert(returnedValue.members, member)
		end

		return returnedValue
	end)
end

--[[
	Lists all private archived threads that the current user has joined. Returns thread and member information.
]]
function GuildBehaviour.Prototype.listJoinedPrivateArchivedThreadsAsync<T>(
	self: Channel<T>,
	before: datetime.DateTime?,
	limit: number?
): future.Future<string>
	return future.new(function()
		local request = self.state.rest:newRequest()

		local status, response = channelRest
			.listJoinedPrivateArchivedThreadsAsync(request, self.id, {
				before = before and before:toIsoDate() or nil,
				limit = limit,
			})
			:await()

		assert(status == "Fulfilled", tostring(response))

		local returnedValue = {
			threads = {},
			members = {},
			hasMore = response.has_more,
		}

		for _, threadData in next, response.threads do
			table.insert(returnedValue.threads, threadData.id)
		end

		for _, threadMemberData in next, response.members do
			local member = threadMember.new(self.state, self.guildId, threadMemberData)

			table.insert(returnedValue.members, member)
		end

		return returnedValue
	end)
end

--[[
	Sets the name of the channel.
]]
function GuildBehaviour.Prototype.setNameAsync<T>(self: Channel<T>, groupName: string): future.Future<Channel<T>>
	return self:modifyAsync({
		name = groupName,
	})
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

	modifyAsync: (self: Channel<T>, json: channelBuilder.JSON, reason: string?) -> future.Future<Channel<T>>,

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
