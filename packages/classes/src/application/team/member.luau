--[[
	Implementation of the Discord Member class in Luau

	https://discord.com/developers/docs/topics/teams#data-models-team-object
]]

local apiTypes = require("@api-types/apiTypes")
local applicationTypes = require("@api-types/application")

local user = require("@classes/user")

local Member = {}

Member.Interface = {}
Member.Prototype = {}

function Member.Prototype.sync(self: Member, memberData: apiTypes.TeamMemberObject)
	self.teamId = memberData.team_id
	self.user = user.new(memberData.user)

	self.membershipState = applicationTypes.MembershipState[memberData.membership_state]

	self.role = (
		memberData.role == "Admin" and "Admin"
		or memberData.role == "Developer" and "Developer"
		or memberData.role == "Read-only" and "ReadOnly"
	) :: applicationTypes.TeamRole
end

function Member.Interface.new(memberData: apiTypes.TeamMemberObject): Member
	local self = setmetatable({} :: Member, { __index = Member.Prototype })

	self:sync(memberData)

	return self
end

export type Member = typeof(Member.Prototype) & {
	membershipState: applicationTypes.MembershipState,
	teamId: apiTypes.Snowflake,
	user: user.User,
	role: applicationTypes.TeamRole,
}

return Member.Interface
