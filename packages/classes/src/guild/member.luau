--[[
	Implementation of the Discord Member class in Luau

	https://discord.com/developers/docs/resources/guild#guild-member-object
]]

local datetime = require("@std-polyfills/datetime")

local apiTypes = require("@api-types/apiTypes")

local guildMemberBitflag = require("@classes/bitflags/guildMember")

local user = require("@classes/user")
local avatarDecoration = require("@classes/avatarDecoration")

local Member = {}

Member.Interface = {}
Member.Prototype = {}

-- https://discord.com/developers/docs/resources/guild#modify-guild-member
-- https://discord.com/developers/docs/resources/guild#modify-current-member
-- https://discord.com/developers/docs/resources/guild#add-guild-member-role
-- https://discord.com/developers/docs/resources/guild#remove-guild-member-role

-- https://discord.com/developers/docs/resources/voice#get-current-user-voice-state
-- https://discord.com/developers/docs/resources/voice#get-user-voice-state
-- https://discord.com/developers/docs/resources/voice#modify-current-user-voice-state
-- https://discord.com/developers/docs/resources/voice#modify-user-voice-state

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

function Member.Interface.new(guildMemberData: apiTypes.GuildMemberObject): Member
	local self = setmetatable({} :: Member, { __index = Member.Prototype })

	self:sync(guildMemberData)

	return self
end

export type Member = typeof(Member.Prototype) & {
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
