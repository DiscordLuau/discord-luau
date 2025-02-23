--[[
	Implementation of the Discord Invite class in Luau

	https://discord.com/developers/docs/resources/invite#invite-object
]]

local apiTypes = require("../../lune_packages/api_types")
local state = require("../../lune_packages/state")
local rest = require("../../lune_packages/rest")
local stdPolyfills = require("../../lune_packages/std_polyfills")
local future = require("../../luau_packages/future")

local unavailableGuild = require("./unavailableGuild")
local scheduledEvent = require("./scheduledEvent")

local user = require("../user")
local application = require("../application/application")

local _require = require :: any

local Invite = {}

Invite.Interface = {}
Invite.Prototype = {}

--[[
	Delete the attached integration object for the guild. Deletes any associated webhooks and kicks the associated bot
	if there is one. Requires the MANAGE_GUILD permission.
]]
function Invite.Prototype.deleteAsync(self: Invite, reason: string?)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.invite.deleteInviteAsync(request, self.code, reason):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return nil
	end) :: future.FutureLike<string, nil>
end

function Invite.Prototype.sync(self: Invite, inviteData: apiTypes.InviteObject)
	if inviteData.channel then
		local channel = _require("../channels/construct")(self.state, inviteData.channel)

		self.channel = channel :: apiTypes.AbstractChannel
	end

	self.type = apiTypes.guild.InviteType[inviteData.type]
	self.code = inviteData.code
	self.guild = inviteData.guild and unavailableGuild.new(self.state, inviteData.guild.id :: string)
	self.inviter = inviteData.inviter and user.new(inviteData.inviter)
	self.targetType = inviteData.target_type and apiTypes.guild.InviteTargetType[inviteData.target_type]
	self.targetUser = inviteData.target_user and user.new(inviteData.target_user)
	self.approximatePresenceCount = inviteData.approximate_presence_count
	self.approximateMemberCount = inviteData.approximate_member_count
	self.expiresAt = inviteData.expires_at and stdPolyfills.datetime.fromIsoDate(inviteData.expires_at)
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

export type Invite = typeof(Invite.Prototype) & {
	state: state.State,

	type: apiTypes.InviteType,
	code: string,
	guild: unavailableGuild.UnavailableGuild?,
	channel: apiTypes.AbstractChannel,
	inviter: user.User?,
	targetType: apiTypes.InviteTargetType?,
	targetUser: user.User?,
	targetApplication: application.Application?,
	approximatePresenceCount: number?,
	approximateMemberCount: number?,
	expiresAt: stdPolyfills.DateTime?,
	scheduledEvent: scheduledEvent.ScheduledEvent?,
}

return Invite.Interface
