--[[
	Implementation of the Discord Member class in Luau

	https://discord.com/developers/docs/resources/guild#guild-member-object
]]

local datetime = require("@std-polyfills/datetime")

local apiTypes = require("@api-types/apiTypes")

local future = require("@vendor/future")

local state = require("@classes/state")

local guildMemberBitflag = require("@classes/bitflags/guildMember")

local guildRest = require("@rest/guild")

local user = require("@classes/user")
local avatarDecoration = require("@classes/avatarDecoration")

local Member = {}

Member.Interface = {}
Member.Prototype = {}

function Member.Prototype.banAsync(
	self: Member,
	reason: string?,
	deleteMessageDays: number?,
	deleteMessageSeconds: number?
)
	return future.new(function()
		local request = self.state.rest:newRequest()

		assert(self.user, "user not found!")

		if deleteMessageSeconds then
			assert(deleteMessageSeconds < 604800, "deleteMessageSeconds must be less than 604800")
			assert(deleteMessageSeconds > 0, "deleteMessageSeconds must be greater than 0")
		end

		if deleteMessageDays then
			assert(deleteMessageDays < 7, "deleteMessageDays must be less than 7")
			assert(deleteMessageDays > 0, "deleteMessageSeconds must be greater than 0")
		end

		local status, response = guildRest
			.createGuildBanAsync(request, self.guildId, self.user.id, {
				delete_message_days = deleteMessageDays,
				delete_message_seconds = deleteMessageSeconds,
			}, reason)
			:await()

		assert(status == "Fulfilled", tostring(response))

		return
	end)
end

function Member.Prototype.kickAsync(self: Member, reason: string?)
	return future.new(function()
		local request = self.state.rest:newRequest()

		assert(self.user, "user not found!")

		local status, response = guildRest.removeGuildMemberAsync(request, self.guildId, self.user.id, reason):await()

		assert(status == "Fulfilled", tostring(response))

		return
	end)
end

function Member.Prototype.modifyAsync(
	self: Member,
	data: {
		nickname: string?,
		roles: { apiTypes.Snowflake }?,
		mute: boolean?,
		deaf: boolean?,
		channelId: apiTypes.Snowflake?,
		communicationDisabledUntil: string?,
	},
	reason: string?
): future.Future<Member>
	return future.new(function()
		local request = self.state.rest:newRequest()

		assert(self.user, "user not found!")

		local status, response = guildRest
			.modifyGuildMemberAsync(request, self.guildId, self.user.id, {
				nick = data.nickname,
				roles = data.roles,
				mute = data.mute,
				deaf = data.deaf,
				channel_id = data.channelId,
				communication_disabled_until = data.communicationDisabledUntil,
			}, reason)
			:await()

		assert(status == "Fulfilled", tostring(response))

		self:sync(response)

		return self
	end)
end

function Member.Prototype.muteAsync(self: Member, reason: string?): future.Future<Member>
	return future.new(function()
		return self:modifyAsync({
			muted = true,
		}, reason)
	end)
end

function Member.Prototype.unmuteAsync(self: Member, reason: string?): future.Future<Member>
	return future.new(function()
		return self:modifyAsync({
			muted = false,
		}, reason)
	end)
end

function Member.Prototype.deafenAsync(self: Member, reason: string?): future.Future<Member>
	return future.new(function()
		return self:modifyAsync({
			deaf = true,
		}, reason)
	end)
end

function Member.Prototype.undeafenAsync(self: Member, reason: string?): future.Future<Member>
	return future.new(function()
		return self:modifyAsync({
			deaf = false,
		}, reason)
	end)
end

function Member.Prototype.setNicknameAsync(self: Member, nickname: string, reason: string?): future.Future<Member>
	return future.new(function()
		return self:modifyAsync({
			nickname = nickname,
		}, reason)
	end)
end

function Member.Prototype.setRolesAsync(
	self: Member,
	roles: { apiTypes.Snowflake },
	reason: string?
): future.Future<Member>
	return future.new(function()
		return self:modifyAsync({
			roles = roles,
		}, reason)
	end)
end

function Member.Prototype.moveVoiceChannelAsync(
	self: Member,
	channelId: apiTypes.Snowflake,
	reason: string?
): future.Future<Member>
	return future.new(function()
		return self:modifyAsync({
			channelId = channelId,
		}, reason)
	end)
end

function Member.Prototype.disableAsync(
	self: Member,
	disabledUntil: datetime.DateTime,
	reason: string?
): future.Future<Member>
	return future.new(function()
		return self:modifyAsync({
			communicationDisabledUntil = disabledUntil:toIsoDate(),
		}, reason)
	end)
end

function Member.Prototype.addRoleAsync(self: Member, roleId: apiTypes.Snowflake, reason: string?): future.Future<Member>
	return future.new(function()
		return future.new(function()
			local request = self.state.rest:newRequest()

			assert(self.user, "user not found!")

			local status, response =
				guildRest.addGuildMemberRoleAsync(request, self.guildId, self.user.id, roleId, reason):await()

			assert(status == "Fulfilled", tostring(response))

			return
		end)
	end)
end

function Member.Prototype.removeRoleAsync(
	self: Member,
	roleId: apiTypes.Snowflake,
	reason: string?
): future.Future<Member>
	return future.new(function()
		return future.new(function()
			local request = self.state.rest:newRequest()

			assert(self.user, "user not found!")

			local status, response =
				guildRest.removeGuildMemberRoleAsync(request, self.guildId, self.user.id, roleId, reason):await()

			assert(status == "Fulfilled", tostring(response))

			return
		end)
	end)
end

function Member.Prototype.sync(self: Member, guildMemberData: apiTypes.GuildMemberObject)
	self.user = guildMemberData.user and user.new(guildMemberData.user)

	self.communicationDisabledUntil = guildMemberData.communication_disabled_until
		and datetime.fromIsoDate(guildMemberData.communication_disabled_until)

	self.avatarDecorationData = guildMemberData.avatar_decoration_data
		and avatarDecoration.new(
			guildMemberData.avatar_decoration_data.asset,
			guildMemberData.avatar_decoration_data.sku_id
		)

	self.flags = guildMemberData.flags and guildMemberBitflag.new(guildMemberData.flags)

	self.joinedAt = datetime.fromIsoDate(guildMemberData.joined_at)
	self.premiumSince = guildMemberData.premium_since and datetime.fromIsoDate(guildMemberData.premium_since)

	self.nick = guildMemberData.nick
	self.avatar = guildMemberData.avatar
	self.roles = guildMemberData.roles
	self.deaf = guildMemberData.deaf
	self.mute = guildMemberData.mute
	self.pending = guildMemberData.pending
	self.permissions = guildMemberData.permissions
end

function Member.Interface.new(
	state: state.State,
	guildId: apiTypes.Snowflake,
	guildMemberData: apiTypes.GuildMemberObject
): Member
	local self = setmetatable(
		{
			state = state,
			guildId = guildId,
		} :: Member,
		{ __index = Member.Prototype }
	)

	self:sync(guildMemberData)

	return self
end

export type Member = typeof(Member.Prototype) & {
	state: state.State,
	guildId: apiTypes.Snowflake,

	user: user.User?,
	nick: string?,
	avatar: string?,
	roles: { apiTypes.Snowflake },
	joinedAt: datetime.DateTime,
	premiumSince: datetime.DateTime?,
	deaf: boolean,
	mute: boolean,
	flags: guildMemberBitflag.GuildMemberBitflag,
	pending: boolean?,
	permissions: string?,
	communicationDisabledUntil: datetime.DateTime?,
	avatarDecorationData: avatarDecoration.AvatarDecoration?,
}

return Member.Interface
