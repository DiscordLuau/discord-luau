local Future = require("@Vendor/Future")

local Construct = require("@Utils/Construct")

local Resolvable = require("@Network/Resolvable")

local GuildRoleBuilder = require("@Builders/GuildRoleBuilder")

local DiscordEndpoints = require("@Data/DiscordEndpoints")

local CacheType = require("@Enums/CacheType")
local ResolvableType = require("@Enums/ResolvableType")

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

	@function updatePositionAsync
	@param position number
	@return Vendor.Future<>
	@within Objects.DiscordGuildRole
]=]
function DiscordGuildRole.Prototype.updatePositionAsync(self: DiscordGuildRole, position: number)
	return Future.try(function()
		return self.discordClient.discordGateway
			:patchAsync(
				string.format(DiscordEndpoints.BotModifyGuildRolePositions, self.guildId),
				Resolvable.new(ResolvableType.JSON, {
					id = self.id,
					position = position,
				})
			)
			:await()
	end)
end

--[=[
	Allows the developer to update/modify a discord role

	@function modifyAsync
	@param position Objects.GuildRoleBuilder
	@return Vendor.Future<>
	@within Objects.DiscordGuildRole
]=]
function DiscordGuildRole.Prototype.modifyAsync(self: DiscordGuildRole, roleBuilder: GuildRoleBuilder.GuildRoleBuilder)
	return Future.try(function()
		return self.discordClient.discordGateway
			:patchAsync(
				string.format(DiscordEndpoints.BotModifyGuildRolePositions, self.guildId, self.id),
				roleBuilder:toPayloadObject()
			)
			:await()
	end)
end

--[=[
	Deletes the Role from the discord guild asynchronously.

	@function deleteAsync
	@return Vendor.Future<>
	@within Objects.DiscordGuildRole
]=]
function DiscordGuildRole.Prototype.deleteAsync(self: DiscordGuildRole)
	return Future.try(function(): ...any
		return self.discordClient.discordGateway
			:deleteAsync(string.format(DiscordEndpoints.BotDeleteGuildRole, self.guildId, self.id))
			:await()
	end)
end

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
	guildId: string,
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

		roleStruct.guildId = guildId

		return Construct(roleStruct, DiscordGuildRole.Prototype)
	end)
end

export type DiscordGuildRole = typeof(DiscordGuildRole.Prototype) & {
	discordClient: any,

	guildId: string,

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
