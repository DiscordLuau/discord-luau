--[[
	Implementation of the Discord Unavailable Guild class in Luau

	https://discord.com/developers/docs/resources/guild#unavailable-guild-object
]]

local future = require("@vendor/future")

local restGuild = require("@rest/guild")
local classGuild = require("@classes/guild/guild")

local apiTypes = require("@api-types/apiTypes")

local state = require("@classes/state")

local UnavailableGuild = {}

UnavailableGuild.Interface = {}
UnavailableGuild.Prototype = {}

--[[
	Asynchronously retrieves the full Guild object for this UnavailableGuild.
]]
function UnavailableGuild.Prototype.getAsync(
	self: UnavailableGuild,
	withCounts: boolean?
): future.Future<classGuild.Guild>
	return future.new(function()
		local guildData = self.state.cache.guilds:get(self.id)

		if guildData then
			return classGuild.new(self.state, guildData)
		end

		local request = self.state.rest:newRequest()
		local status, response = restGuild
			.getGuildAsync(request, self.id, {
				withCounts = withCounts,
			})
			:await()

		assert(status == "Fulfilled", response)

		self.state.cache.guilds:set(self.id, response)

		return classGuild.new(self.state, response)
	end)
end

function UnavailableGuild.Interface.new(state: state.State, id: apiTypes.Snowflake): UnavailableGuild
	local self = setmetatable(
		{
			state = state,

			id = id,
			isUnavailable = true,
		} :: UnavailableGuild,
		{ __index = UnavailableGuild.Prototype }
	)

	return self
end

export type UnavailableGuild = typeof(UnavailableGuild.Prototype) & {
	state: state.State,

	id: apiTypes.Snowflake,
	isUnavailable: boolean,
}

return UnavailableGuild.Interface
