local Construct = require("../../Utils/Construct")

local CacheType = require("../../Enums/CacheType")

--[=[
	@class Objects.DiscordGuildRole

	The `DiscordGuildRole` class represents a role in a Discord guild (server) and provides a structure for role data.
]=]
local DiscordGuildRole = {}

DiscordGuildRole.Prototype = {}
DiscordGuildRole.Interface = {}

--[=[
	@prop type string
	@within Objects.DiscordGuildRole
	@readonly

	The type of the DiscordGuildRole. Default is "DiscordGuildRole".
]=]
DiscordGuildRole.Prototype.type = "DiscordGuildRole"

--[=[
	Creates a new DiscordGuildRole instance.

	@function new
	@param discordClient any -- The Discord client instance.
	@param roleData table -- The raw data for the role.
	@return DiscordGuildRole -- The newly created DiscordGuildRole instance.
	@within Objects.DiscordGuildRole
]=]
function DiscordGuildRole.Interface.new(
	discordClient: any,
	roleData: {
		id: string,
		name: string,
		permissions: string,
		position: number,
		color: number,
		hoist: boolean,
		managed: boolean,
		mentionable: boolean,
	}
)
	return discordClient.discordCache:getDataOr(CacheType.DiscordGuildRole, roleData.id, function()
		local roleStruct = {
			discordClient = discordClient,
		}

		for index, value in roleData do
			roleStruct[index] = value
		end

		return Construct(roleStruct, DiscordGuildRole.Prototype)
	end)
end

export type DiscordGuildRole = typeof(DiscordGuildRole.Prototype) & {
	id: string,
	name: string,
	permissions: string,
	position: number,
	color: number,
	hoist: boolean,
	managed: boolean,
	mentionable: boolean,
}

return DiscordGuildRole.Interface
