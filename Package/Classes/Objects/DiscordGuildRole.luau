local Construct = require("../../Utils/Construct")

local CacheType = require("../../Enums/CacheType")

--[=[
	@class Objects.DiscordGuildRole

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local DiscordGuildRole = {}

DiscordGuildRole.Prototype = {}
DiscordGuildRole.Interface = {}

DiscordGuildRole.Prototype.type = "DiscordGuildRole"

function DiscordGuildRole.Interface.new(discordClient: any, roleData: {
	id: string,
	name: string,
	permissions: string,
	position: number,
	color: number,
	hoist: boolean,
	managed: boolean,
	mentionable: boolean
})
	return discordClient.discordCache:getDataOr(CacheType.DiscordGuildRole, roleData.id, function()
		local roleStruct = {
			discordClient = discordClient
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
	mentionable: boolean
}

return DiscordGuildRole.Interface