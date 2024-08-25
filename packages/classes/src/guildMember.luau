--[[
	Implementation of the Discord GuildMember class in Luau

	https://discord.com/developers/docs/resources/guild#guild-member-object
]]

local datetime = require("@std-polyfills/datetime")

local apiTypes = require("@api-types/apiTypes")

local guildMemberBitflag = require("@classes/bitflags/guildMember")

local user = require("@classes/user")
local avatarDecoration = require("@classes/avatarDecoration")

local GuildMember = {}

GuildMember.Interface = {}
GuildMember.Prototype = {}

function GuildMember.Prototype.sync(self: GuildMember, guildMemberData: apiTypes.GuildMemberObject)
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

function GuildMember.Interface.new(guildMemberData: apiTypes.GuildMemberObject): GuildMember
	local self = setmetatable({} :: GuildMember, { __index = GuildMember.Prototype })

	self:sync(guildMemberData)

	return self
end

export type GuildMember = typeof(GuildMember.Prototype) & {
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

return GuildMember.Interface
