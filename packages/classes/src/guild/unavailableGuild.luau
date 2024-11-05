--[[
	Implementation of the Discord Unavailable Guild class in Luau

	https://discord.com/developers/docs/resources/guild#unavailable-guild-object
]]

local apiTypes = require("@api-types/apiTypes")

local state = require("@classes/state")

local UnavailableGuild = {}

UnavailableGuild.Interface = {}
UnavailableGuild.Prototype = {}

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
