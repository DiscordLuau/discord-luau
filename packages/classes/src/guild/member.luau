--[[
	Implementation of the Discord Member class in Luau

	https://discord.com/developers/docs/resources/guild#guild-member-object
]]

local apiTypes = require("../../lune_packages/api_types")
local rest = require("../../lune_packages/rest")
local future = require("../../luau_packages/future")
local state = require("../../lune_packages/state")
local stdPolyfills = require("../../lune_packages/std_polyfills")

local user = require("../user")
local avatarDecoration = require("../avatarDecoration")
local guildMemberBitflag = require("../bitflags/guildMember")

local Member = {}

Member.Interface = {}
Member.Prototype = {}

--[[
	Create a guild ban, and optionally delete previous messages sent by the banned user.
]]
function Member.Prototype.banAsync(
	self: Member,
	reason: string?,
	deleteMessageDays: number?,
	deleteMessageSeconds: number?
)
	return future.Future.new(function()
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

		local response = rest.guild
			.createGuildBanAsync(request, self.guildId, self.user.id, {
				delete_message_days = deleteMessageDays,
				delete_message_seconds = deleteMessageSeconds,
			}, reason)
			:await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return nil
	end) :: future.FutureLike<string, nil>
end

--[[
	Removes a role from a guild member. Requires the MANAGE_ROLES permission.
]]
function Member.Prototype.kickAsync(self: Member, reason: string?)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		assert(self.user, "user not found!")

		local response = rest.guild.removeGuildMemberAsync(request, self.guildId, self.user.id, reason):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return nil
	end) :: future.FutureLike<string, nil>
end

--[[
	Modify attributes of a guild member. Returns updated guild member. If the channel_id is set to null, this will
	force the target user to be disconnected from voice.
]]
function Member.Prototype.modifyAsync(
	self: Member,
	data: {
		nickname: string?,
		roles: { apiTypes.Snowflake }?,
		mute: boolean?,
		deaf: boolean?,
		channelId: (apiTypes.Snowflake | boolean)?,
		communicationDisabledUntil: string?,
	},
	reason: string?
)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		assert(self.user, "user not found!")

		local response = rest.guild
			.modifyGuildMemberAsync(request, self.guildId, self.user.id, {
				nick = data.nickname,
				roles = data.roles,
				mute = data.mute,
				deaf = data.deaf,
				channel_id = data.channelId,
				communication_disabled_until = data.communicationDisabledUntil,
			}, reason)
			:await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		self:sync(response:unwrapOk())

		return self
	end) :: future.FutureLike<string, Member>
end

--[[
	will mute the user in voice channels the user is in. Returns the updated Member.
]]
function Member.Prototype.muteAsync(self: Member, reason: string?)
	return self:modifyAsync({
		muted = true,
	}, reason)
end

--[[
	will unmute the user in voice channels the user is in. Returns the updated Member.
]]
function Member.Prototype.unmuteAsync(self: Member, reason: string?)
	return self:modifyAsync({
		muted = false,
	}, reason)
end

--[[
	will deafen the user in voice channels the user is in. Returns the updated Member.
]]
function Member.Prototype.deafenAsync(self: Member, reason: string?)
	return self:modifyAsync({
		deaf = true,
	}, reason)
end

--[[
	will undeafen the user in voice channels the user is in. Returns the updated Member.
]]
function Member.Prototype.undeafenAsync(self: Member, reason: string?)
	return self:modifyAsync({
		deaf = false,
	}, reason)
end

--[[
	will set the nickname of the user. Returns the updated Member.
]]
function Member.Prototype.setNicknameAsync(self: Member, nickname: string, reason: string?)
	return self:modifyAsync({
		nickname = nickname,
	}, reason)
end

--[[
	will set all roles that the user has in this guild. Returns the updated Member.
]]
function Member.Prototype.setRolesAsync(self: Member, roles: { apiTypes.Snowflake }, reason: string?)
	return self:modifyAsync({
		roles = roles,
	}, reason)
end

--[[
	will move the user between different voice channels. Returns the updated Member.
]]
function Member.Prototype.moveVoiceChannelAsync(self: Member, channelId: apiTypes.Snowflake, reason: string?)
	return self:modifyAsync({
		channelId = channelId,
	}, reason)
end

--[[
	will disconnect the user from voice channels the user is in. Returns the updated Member.
]]
function Member.Prototype.disconnectFromVoiceChannelAsync(self: Member, reason: string?)
	return self:modifyAsync({
		channelId = false,
	}, reason)
end

--[[
	Disables the users communication up to a specific time. Returns the updated Member.
]]
function Member.Prototype.disableAsync(self: Member, disabledUntil: stdPolyfills.DateTime, reason: string?)
	return self:modifyAsync({
		communicationDisabledUntil = disabledUntil:toIsoDate(),
	}, reason)
end

--[[
	Add a role to a guild member.
]]
function Member.Prototype.addRoleAsync(self: Member, roleId: apiTypes.Snowflake, reason: string?)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		assert(self.user, "user not found!")

		local response = rest.guild.addGuildMemberRoleAsync(request, self.guildId, self.user.id, roleId, reason):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return nil
	end) :: future.FutureLike<string, nil>
end

--[[
	Remove a role from a guild member.
]]
function Member.Prototype.removeRoleAsync(self: Member, roleId: apiTypes.Snowflake, reason: string?)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		assert(self.user, "user not found!")

		local response =
			rest.guild.removeGuildMemberRoleAsync(request, self.guildId, self.user.id, roleId, reason):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return nil
	end) :: future.FutureLike<string, nil>
end

function Member.Prototype.sync(self: Member, guildMemberData: apiTypes.GuildMemberObject)
	self.user = guildMemberData.user and user.new(guildMemberData.user)

	self.communicationDisabledUntil = guildMemberData.communication_disabled_until
		and stdPolyfills.datetime.fromIsoDate(guildMemberData.communication_disabled_until)

	self.avatarDecorationData = guildMemberData.avatar_decoration_data
		and avatarDecoration.new(
			guildMemberData.avatar_decoration_data.asset,
			guildMemberData.avatar_decoration_data.sku_id
		)

	self.flags = guildMemberData.flags and guildMemberBitflag.new(guildMemberData.flags)

	self.joinedAt = stdPolyfills.datetime.fromIsoDate(guildMemberData.joined_at)
	self.premiumSince = guildMemberData.premium_since
		and stdPolyfills.datetime.fromIsoDate(guildMemberData.premium_since)

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
	joinedAt: stdPolyfills.DateTime,
	premiumSince: stdPolyfills.DateTime?,
	deaf: boolean,
	mute: boolean,
	flags: guildMemberBitflag.GuildMemberBitflag,
	pending: boolean?,
	permissions: string?,
	communicationDisabledUntil: stdPolyfills.DateTime?,
	avatarDecorationData: avatarDecoration.AvatarDecoration?,
}

return Member.Interface
