--[=[
	@class Classes.UnavailableGuild
	@__index Prototype

	Implementation of the Discord Unavailable Guild class in Luau

	https://discord.com/developers/docs/resources/guild#unavailable-guild-object
]=]

local apiTypes = require("../../lune_packages/api_types")
local state = require("../../lune_packages/state")

local UnavailableGuild = {}

UnavailableGuild.Interface = {}
UnavailableGuild.Prototype = {}

--[=[
	@within Classes.UnavailableGuild
	@private

	Responsible for constructing this class.
]=]
function UnavailableGuild.Interface.new(state: state.State, id: apiTypes.Snowflake): UnavailableGuild
	local self = setmetatable(
		{
			--[=[
				@prop state Classes.State
				@within Classes.UnavailableGuild
				The state object that manages this guild's data and caching
			]=]
			state = state,

			--[=[
				@prop id string
				@within Classes.UnavailableGuild
				The unique identifier for this guild as a Discord snowflake
			]=]
			id = id,

			--[=[
				@prop isUnavailable boolean
				@within Classes.UnavailableGuild
				Indicates whether this guild is currently unavailable, typically due to an outage
			]=]
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
