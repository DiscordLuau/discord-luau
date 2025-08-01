--[=[
	@class Classes.Team
	@__index Prototype

	Implementation of the Discord Team class in Luau

	https://discord.com/developers/docs/topics/teams#data-models-team-object
]=]

local apiTypes = require("../../../lune_packages/api_types")

local member = require("./member")

local Team = {}

Team.Interface = {}
Team.Prototype = {}

--[=[
	@within Classes.Team
	@private

	Responsible for syncing data to this team object. This is typically called by the API when this object is
	created or updated.
]=]
function Team.Prototype.sync(self: Team, teamData: apiTypes.TeamObject)
	local memberArray = {}

	for _, memberData in teamData.members do
		table.insert(memberArray, member.new(memberData))
	end

	--[=[
		@prop icon string?
		@within Classes.Team
		The icon hash of the team
	]=]
	self.icon = teamData.icon

	--[=[
		@prop id string
		@within Classes.Team
		The unique identifier of the team
	]=]
	self.id = teamData.id

	--[=[
		@prop members { Classes.TeamMember }
		@within Classes.Team
		Array of team members in this team
	]=]
	self.members = memberArray

	--[=[
		@prop name string
		@within Classes.Team
		The name of the team
	]=]
	self.name = teamData.name

	--[=[
		@prop ownerUserId string
		@within Classes.Team
		The user ID of the team owner
	]=]
	self.ownerUserId = teamData.owner_user_id
end

--[=[
	@within Classes.Team
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
