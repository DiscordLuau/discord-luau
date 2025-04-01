--[=[
	@class Classes.TeamMember
	@__index Prototype

	Implementation of the Discord Member class in Luau

	https://discord.com/developers/docs/topics/teams#data-models-team-object
]=]

local apiTypes = require("../../../lune_packages/api_types")

local user = require("../../user")

local Member = {}

Member.Interface = {}
Member.Prototype = {}

--[=[
	@within Classes.TeamMember
	@private

	Responsible for syncing data to this member object. This is typically called by the API when this object is
	created or updated.
]=]
function Member.Prototype.sync(self: Member, memberData: apiTypes.TeamMemberObject)
	--[=[
		@prop membershipState apiTypes.MembershipState
		@within Classes.TeamMember

		The state of the team member's membership. Represents the current status of this member within the team.
	]=]
	self.membershipState = apiTypes.application.MembershipState[memberData.membership_state]

	--[=[
		@prop teamId string
		@within Classes.TeamMember

		The unique identifier of the team this member belongs to.
	]=]
	self.teamId = memberData.team_id

	--[=[
		@prop user Classes.User
		@within Classes.TeamMember

		The user object associated with this team member. Contains detailed information about the user's profile.
	]=]
	self.user = user.new(memberData.user)

	--[=[
		@prop role apiTypes.TeamRole
		@within Classes.TeamMember

		The role assigned to this team member. Can be either Admin, Developer, or ReadOnly, determining their permissions.
	]=]
	self.role = (
		memberData.role == "Admin" and "Admin"
		or memberData.role == "Developer" and "Developer"
		or memberData.role == "Read-only" and "ReadOnly"
	) :: apiTypes.TeamRole
end

--[=[
	@within Classes.TeamMember
	@private

	Responsible for constructing this class.
]=]
function Member.Interface.new(memberData: apiTypes.TeamMemberObject): Member
	local self = setmetatable({} :: Member, { __index = Member.Prototype })

	self:sync(memberData)

	return self
end

export type Member = typeof(Member.Prototype) & {
	membershipState: apiTypes.MembershipState,
	teamId: apiTypes.Snowflake,
	user: user.User,
	role: apiTypes.TeamRole,
}

return Member.Interface
