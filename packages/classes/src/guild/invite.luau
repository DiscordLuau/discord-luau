--[[
	Implementation of the Discord Invite class in Luau

	https://discord.com/developers/docs/resources/invite#invite-object
]]

local datetime = require("@std-polyfills/datetime")

local apiTypes = require("@api-types/apiTypes")
local guildTypes = require("@api-types/guild")

local unavailableGuild = require("@classes/guild/unavailableGuild")

local guildAnnouncement = require("@classes/channels/types/guildAnnouncement")
local guildCategory = require("@classes/channels/types/guildCategory")
local guildDirectory = require("@classes/channels/types/guildDirectory")
local guildStageVoice = require("@classes/channels/types/guildStageVoice")
local guildText = require("@classes/channels/types/guildText")
local guildVoice = require("@classes/channels/types/guildVoice")

local user = require("@classes/user")
local application = require("@classes/application/application")
local scheduledEvent = require("@classes/guild/scheduledEvent")

local state = require("@classes/state")

local constructChannelFromData = require("@utils/constructChannelFromData")

local Invite = {}

Invite.Interface = {}
Invite.Prototype = {}

function Invite.Prototype.sync(self: Invite, inviteData: apiTypes.InviteObject)
	if inviteData.channel then
		local channel = constructChannelFromData(inviteData.channel)

		self.channel = channel :: channel
	end

	self.type = guildTypes.InviteType[inviteData.type]
	self.code = inviteData.code
	self.guild = inviteData.guild and unavailableGuild.new(self.state, inviteData.guild.id :: string)
	self.inviter = inviteData.inviter and user.new(inviteData.inviter)
	self.targetType = inviteData.target_type and guildTypes.InviteTargetType[inviteData.target_type]
	self.targetUser = inviteData.target_user and user.new(inviteData.target_user)
	self.approximatePresenceCount = inviteData.approximate_presence_count
	self.approximateMemberCount = inviteData.approximate_member_count
	self.expiresAt = inviteData.expires_at and datetime.fromIsoDate(inviteData.expires_at)
	self.scheduledEvent = inviteData.guild_scheduled_event and scheduledEvent.new(inviteData.guild_scheduled_event)
end

function Invite.Interface.new(state: state.State, inviteData: apiTypes.InviteObject): Invite
	local self = setmetatable(
		{
			state = state,
		} :: Invite,
		{ __index = Invite.Prototype }
	)

	self:sync(inviteData)

	return self
end

type channel =
	guildAnnouncement.GuildAnnouncement
	| guildCategory.GuildCategory
	| guildDirectory.GuildDirectory
	| guildStageVoice.GuildStageVoice
	| guildText.GuildText
	| guildVoice.GuildVoice

export type Invite = typeof(Invite.Prototype) & {
	state: state.State,

	type: guildTypes.InviteType,
	code: string,
	guild: unavailableGuild.UnavailableGuild?,
	channel: channel,
	inviter: user.User?,
	targetType: guildTypes.InviteTargetType?,
	targetUser: user.User?,
	targetApplication: application.Application?,
	approximatePresenceCount: number?,
	approximateMemberCount: number?,
	expiresAt: datetime.DateTime?,
	scheduledEvent: scheduledEvent.ScheduledEvent?,
}

return Invite.Interface
