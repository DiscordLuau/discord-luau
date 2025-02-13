--[[
	Implementation of the Discord Member class in Luau

	https://discord.com/developers/docs/topics/teams#data-models-team-object
]]

local apiTypes = require("../../../lune_packages/api_types")

local user = require("../../user")

local Member = {}

Member.Interface = {}
Member.Prototype = {}

function Member.Prototype.sync(self: Member, memberData: apiTypes.TeamMemberObject)
	self.teamId = memberData.team_id
	self.user = user.new(memberData.user)

	self.membershipState = apiTypes.application.MembershipState[memberData.membership_state]

	self.role = (
		memberData.role == "Admin" and "Admin"
		or memberData.role == "Developer" and "Developer"
		or memberData.role == "Read-only" and "ReadOnly"
	) :: apiTypes.TeamRole
end

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
