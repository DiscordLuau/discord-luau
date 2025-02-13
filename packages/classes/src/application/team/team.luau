--[[
	Implementation of the Discord Team class in Luau

	https://discord.com/developers/docs/topics/teams#data-models-team-object
]]

local apiTypes = require("../../../lune_packages/api_types")

local member = require("./member")

local Team = {}

Team.Interface = {}
Team.Prototype = {}

function Team.Prototype.sync(self: Team, teamData: apiTypes.TeamObject)
	local memberArray = {}

	for _, memberData in teamData.members do
		table.insert(memberArray, member.new(memberData))
	end

	self.icon = teamData.icon
	self.id = teamData.id
	self.members = memberArray
	self.name = teamData.name
	self.ownerUserId = teamData.owner_user_id
end

function Team.Interface.new(teamData: apiTypes.TeamObject): Team
	local self = setmetatable({} :: Team, { __index = Team.Prototype })

	self:sync(teamData)

	return self
end

export type Team = typeof(Team.Prototype) & {
	icon: string?,
	id: apiTypes.Snowflake,
	members: { member.Member },
	name: string,
	ownerUserId: apiTypes.Snowflake,
}

return Team.Interface
