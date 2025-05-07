--[=[
	@class Classes.Member
	@__index Member.Prototype
	
	Implementation of the Discord Member class in Luau
	
	https://discord.com/developers/docs/resources/guild#guild-member-object
]=]

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

--[=[
	@within Classes.Member
	Create a guild ban, and optionally delete previous messages sent by the banned user.
]=]
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

--[=[
	@within Classes.Member
	Removes a role from a guild member. Requires the MANAGE_ROLES permission.
]=]
function Member.Prototype.kickAsync(self: Member, reason: string?)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		assert(self.user, "user not found!")

		local response = rest.guild.removeGuildMemberAsync(request, self.guildId, self.user.id, reason):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return nil
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Classes.Member
	Modify attributes of a guild member. Returns updated guild member. If the channel_id is set to null, this will
	force the target user to be disconnected from voice.
]=]
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

--[=[
	@within Classes.Member
	Will mute the user in voice channels the user is in. Returns the updated Member.
]=]
function Member.Prototype.muteAsync(self: Member, reason: string?)
	return self:modifyAsync({
		muted = true,
	}, reason)
end

--[=[
	@within Classes.Member
	Will unmute the user in voice channels the user is in. Returns the updated Member.
]=]
function Member.Prototype.unmuteAsync(self: Member, reason: string?)
	return self:modifyAsync({
		muted = false,
	}, reason)
end

--[=[
	@within Classes.Member
	Will deafen the user in voice channels the user is in. Returns the updated Member.
]=]
function Member.Prototype.deafenAsync(self: Member, reason: string?)
	return self:modifyAsync({
		deaf = true,
	}, reason)
end

--[=[
	@within Classes.Member
	Will undeafen the user in voice channels the user is in. Returns the updated Member.
]=]
function Member.Prototype.undeafenAsync(self: Member, reason: string?)
	return self:modifyAsync({
		deaf = false,
	}, reason)
end

--[=[
	@within Classes.Member
	Will set the nickname of the user. Returns the updated Member.
]=]
function Member.Prototype.setNicknameAsync(self: Member, nickname: string, reason: string?)
	return self:modifyAsync({
		nickname = nickname,
	}, reason)
end

--[=[
	@within Classes.Member
	Will set all roles that the user has in this guild. Returns the updated Member.
]=]
function Member.Prototype.setRolesAsync(self: Member, roles: { apiTypes.Snowflake }, reason: string?)
	return self:modifyAsync({
		roles = roles,
	}, reason)
end

--[=[
	@within Classes.Member
	Will move the user between different voice channels. Returns the updated Member.
]=]
function Member.Prototype.moveVoiceChannelAsync(self: Member, channelId: apiTypes.Snowflake, reason: string?)
	return self:modifyAsync({
		channelId = channelId,
	}, reason)
end

--[=[
	@within Classes.Member
	Will disconnect the user from voice channels the user is in. Returns the updated Member.
]=]
function Member.Prototype.disconnectFromVoiceChannelAsync(self: Member, reason: string?)
	return self:modifyAsync({
		channelId = false,
	}, reason)
end

--[=[
	@within Classes.Member
	Disables the users communication up to a specific time. Returns the updated Member.
]=]
function Member.Prototype.disableAsync(self: Member, disabledUntil: stdPolyfills.DateTime, reason: string?)
	return self:modifyAsync({
		communicationDisabledUntil = disabledUntil:toIsoDate(),
	}, reason)
end

--[=[
	@within Classes.Member
	Add a role to a guild member.
]=]
function Member.Prototype.addRoleAsync(self: Member, roleId: apiTypes.Snowflake, reason: string?)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		assert(self.user, "user not found!")

		local response = rest.guild.addGuildMemberRoleAsync(request, self.guildId, self.user.id, roleId, reason):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return nil
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Classes.Member
	Remove a role from a guild member.
]=]
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

--[=[
	@within Classes.Member
	@private
	Synchronizes the member object with the data from the API.
]=]
function Member.Prototype.sync(self: Member, guildMemberData: apiTypes.GuildMemberObject)
	--[=[
		@within Classes.Member
		@prop user Classes.User
		The user this member represents.
	]=]
	self.user = guildMemberData.user and user.new(guildMemberData.user)

	--[=[
		@within Classes.Member
		@prop communicationDisabledUntil DateTime
		When the member's communication is disabled until.
	]=]
	self.communicationDisabledUntil = guildMemberData.communication_disabled_until
		and stdPolyfills.datetime.fromIsoDate(guildMemberData.communication_disabled_until)

	--[=[
		@within Classes.Member
		@prop avatarDecorationData Classes.AvatarDecoration
		The member's avatar decoration data.
	]=]
	self.avatarDecorationData = guildMemberData.avatar_decoration_data
		and avatarDecoration.new(
			guildMemberData.avatar_decoration_data.asset,
			guildMemberData.avatar_decoration_data.sku_id
		)

	--[=[
		@within Classes.Member
		@prop flags Classes.GuildMemberBitflag
		Member flags combined as a bitfield.
	]=]
	self.flags = guildMemberData.flags and guildMemberBitflag.new(guildMemberData.flags)

	--[=[
		@within Classes.Member
		@prop joinedAt DateTime
		When the member joined the guild.
	]=]
	self.joinedAt = stdPolyfills.datetime.fromIsoDate(guildMemberData.joined_at)

	--[=[
		@within Classes.Member
		@prop premiumSince DateTime
		When the member started boosting the guild.
	]=]
	self.premiumSince = guildMemberData.premium_since
		and stdPolyfills.datetime.fromIsoDate(guildMemberData.premium_since)

	--[=[
		@within Classes.Member
		@prop nick string
		The member's nickname.
	]=]
	self.nick = guildMemberData.nick

	--[=[
		@within Classes.Member
		@prop avatar string
		The member's avatar hash.
	]=]
	self.avatar = guildMemberData.avatar

	--[=[
		@within Classes.Member
		@prop roles { string }
		The member's role IDs.
	]=]
	self.roles = guildMemberData.roles

	--[=[
		@within Classes.Member
		@prop deaf boolean
		Whether the member is deafened.
	]=]
	self.deaf = guildMemberData.deaf

	--[=[
		@within Classes.Member
		@prop mute boolean
		Whether the member is muted.
	]=]
	self.mute = guildMemberData.mute

	--[=[
		@within Classes.Member
		@prop pending boolean
		Whether the member has not yet passed the guild's Membership Screening requirements.
	]=]
	self.pending = guildMemberData.pending

	--[=[
		@within Classes.Member
		@prop permissions string
		The member's permissions.
	]=]
	self.permissions = guildMemberData.permissions
end

--[=[
	@private
	@within Classes.Member
	Creates a new Member instance with the specified member data.
]=]
function Member.Interface.new(
	state: state.State,
	guildId: apiTypes.Snowflake,
	guildMemberData: apiTypes.GuildMemberObject
): Member
	local self = setmetatable(
		{
			--[=[
				@within Classes.Member
				@prop state State
				The state object for this member.
			]=]
			state = state,

			--[=[
				@within Classes.Member
				@prop guildId string
				The ID of the guild this member belongs to.
			]=]
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
