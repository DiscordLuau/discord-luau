--[=[
	@class Classes.Application.Team
	@__index Prototype

	Implementation of the Discord Team class in Luau

	https://discord.com/developers/docs/topics/teams#data-models-team-object
]=]

--[=[
	@prop icon string?
	@within Classes.Application.Team
	The icon hash of the team
]=]

--[=[
	@prop id string
	@within Classes.Application.Team
	The unique identifier of the team
]=]

--[=[
	@prop members { Classes.Application.TeamMember }
	@within Classes.Application.Team
	Array of team members in this team
]=]

--[=[
	@prop name string
	@within Classes.Application.Team
	The name of the team
]=]

--[=[
	@prop ownerUserId string
	@within Classes.Application.Team
	The user ID of the team owner
]=]

local apiTypes = require("../../../luau_packages/api_types")

local member = require("./member")

local Team = {}

Team.Interface = {}
Team.Prototype = {}

--[=[
	@within Classes.Application.Team
	@private

	Responsible for syncing data to this team object. This is typically called by the API when this object is
	created or updated.
]=]
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

--[=[
	@within Classes.Application.Team
	@private

	Responsible for constructing this class.
]=]
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
