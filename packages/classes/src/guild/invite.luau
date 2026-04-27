--[=[
	@class Classes.Guild.Invite
	@__index Prototype

	Implementation of the Discord Invite class in Luau

	https://discord.com/developers/docs/resources/invite#invite-object
]=]

--[=[
	@prop channel Classes.Channels.Channel
	@within Classes.Guild.Invite
	The channel this invite is for
]=]

--[=[
	@prop type string
	@within Classes.Guild.Invite
	The type of invite (GUILD, GROUP_DM, FRIEND)
]=]

--[=[
	@prop code string
	@within Classes.Guild.Invite
	The unique invite code
]=]

--[=[
	@prop guild Classes.UnavailableGuild?
	@within Classes.Guild.Invite
	The guild this invite is for
]=]

--[=[
	@prop inviter Classes.User?
	@within Classes.Guild.Invite
	The user who created the invite
]=]

--[=[
	@prop targetType string?
	@within Classes.Guild.Invite
	The type of target for this invite (STREAM, EMBEDDED_APPLICATION)
]=]

--[=[
	@prop targetUser Classes.User?
	@within Classes.Guild.Invite
	The user whose stream to display for this invite, if targetType is STREAM
]=]

--[=[
	@prop approximatePresenceCount number?
	@within Classes.Guild.Invite
	Approximate count of online members (only present when target_user is set)
]=]

--[=[
	@prop approximateMemberCount number?
	@within Classes.Guild.Invite
	Approximate count of total members
]=]

--[=[
	@prop expiresAt stdPolyfills.DateTime?
	@within Classes.Guild.Invite
	The expiration date of this invite
]=]

--[=[
	@prop scheduledEvent Classes.Guild.ScheduledEvent?
	@within Classes.Guild.Invite
	The scheduled event associated with this invite
]=]

local apiTypes = require("../../luau_packages/api_types")
local state = require("../../luau_packages/state")
local rest = require("../../luau_packages/rest")
local stdPolyfills = require("../../luau_packages/std_polyfills")
local future = require("../../luau_packages/future")

local unavailableGuild = require("./unavailableGuild")
local scheduledEvent = require("./scheduledEvent")

local user = require("../user")
local application = require("../application/application")

local _require = require :: any

local Invite = {}

Invite.Interface = {}
Invite.Prototype = {}

--[=[
	@within Classes.Guild.Invite
	Delete the attached integration object for the guild. Deletes any associated webhooks and kicks the associated bot
	if there is one. Requires the MANAGE_GUILD permission.
]=]
function Invite.Prototype.deleteAsync(self: Invite, reason: string?)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.invite.deleteInviteAsync(request, self.code, reason):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return nil
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Classes.Guild.Invite
	@private

	Responsible for syncing data to this invite object. This is typically called by the API when this object is
	created or updated.
]=]
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

--[=[
	@within Classes.Guild.Invite
	@private

	Responsible for constructing this class.
]=]
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
