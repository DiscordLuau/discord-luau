--[=[
	@class Classes.Invite
	@__index Prototype

	Implementation of the Discord Invite class in Luau

	https://discord.com/developers/docs/resources/invite#invite-object
]=]

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

--[=[
	@within Classes.Invite
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
	@within Classes.Invite
	@private

	Responsible for syncing data to this invite object. This is typically called by the API when this object is
	created or updated.
]=]
function Invite.Prototype.sync(self: Invite, inviteData: apiTypes.InviteObject)
	--[=[
		@prop channel Classes.Channel
		@within Classes.Invite
		The channel this invite is for
	]=]
	if inviteData.channel then
		local channel = _require("../channels/construct")(self.state, inviteData.channel)
		self.channel = channel :: apiTypes.AbstractChannel
	end

	--[=[
		@prop type string
		@within Classes.Invite
		The type of invite (GUILD, GROUP_DM, FRIEND)
	]=]
	self.type = apiTypes.guild.InviteType[inviteData.type]

	--[=[
		@prop code string
		@within Classes.Invite
		The unique invite code
	]=]
	self.code = inviteData.code

	--[=[
		@prop guild Classes.UnavailableGuild?
		@within Classes.Invite
		The guild this invite is for
	]=]
	self.guild = inviteData.guild and unavailableGuild.new(self.state, inviteData.guild.id :: string)

	--[=[
		@prop inviter Classes.User?
		@within Classes.Invite
		The user who created the invite
	]=]
	self.inviter = inviteData.inviter and user.new(inviteData.inviter)

	--[=[
		@prop targetType string?
		@within Classes.Invite
		The type of target for this invite (STREAM, EMBEDDED_APPLICATION)
	]=]
	self.targetType = inviteData.target_type and apiTypes.guild.InviteTargetType[inviteData.target_type]

	--[=[
		@prop targetUser Classes.User?
		@within Classes.Invite
		The user whose stream to display for this invite, if targetType is STREAM
	]=]
	self.targetUser = inviteData.target_user and user.new(inviteData.target_user)

	--[=[
		@prop approximatePresenceCount number?
		@within Classes.Invite
		Approximate count of online members (only present when target_user is set)
	]=]
	self.approximatePresenceCount = inviteData.approximate_presence_count

	--[=[
		@prop approximateMemberCount number?
		@within Classes.Invite
		Approximate count of total members
	]=]
	self.approximateMemberCount = inviteData.approximate_member_count

	--[=[
		@prop expiresAt stdPolyfills.DateTime?
		@within Classes.Invite
		The expiration date of this invite
	]=]
	self.expiresAt = inviteData.expires_at and stdPolyfills.datetime.fromIsoDate(inviteData.expires_at)

	--[=[
		@prop scheduledEvent Classes.ScheduledEvent?
		@within Classes.Invite
		The scheduled event associated with this invite
	]=]
	self.scheduledEvent = inviteData.guild_scheduled_event and scheduledEvent.new(inviteData.guild_scheduled_event)
end

--[=[
	@within Classes.Invite
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
