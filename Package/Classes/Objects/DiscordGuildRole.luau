local Future = require("@Vendor/Future")

local Construct = require("@Utils/Construct")

local Resolvable = require("@Network/Resolvable")

local GuildRoleBuilder = require("@Builders/GuildRoleBuilder")
local PermissionsBuilder = require("@Builders/PermissionsBuilder")

local DiscordEndpoints = require("@Data/DiscordEndpoints")

local CacheType = require("@Enums/CacheType")
local ResolvableType = require("@Enums/ResolvableType")

--[=[
	@class Objects.DiscordGuildRole

	The `DiscordGuildRole` class represents a role in a Discord guild (server) and provides a structure for role data.
]=]

--[=[
	@prop guildId string
	@within Objects.DiscordGuildRole
]=]

--[=[
	@prop id string
	@within Objects.DiscordGuildRole
]=]

--[=[
	@prop name string
	@within Objects.DiscordGuildRole
]=]

--[=[
	@prop permissions string
	@within Objects.DiscordGuildRole
]=]

--[=[
	@prop position number
	@within Objects.DiscordGuildRole
]=]

--[=[
	@prop color number
	@within Objects.DiscordGuildRole
]=]

--[=[
	@prop hoist boolean
	@within Objects.DiscordGuildRole
]=]

--[=[
	@prop managed boolean
	@within Objects.DiscordGuildRole
]=]

--[=[
	@prop mentionable boolean
	@within Objects.DiscordGuildRole
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
	roleData: {
		id: string,

		[string]: any,
	}
)
	local self = discordClient.discordCache:getDataOr(CacheType.DiscordGuildRole, roleData.id, function()
		local roleStruct = {
			discordClient = discordClient,
		}

		return Construct(roleStruct, DiscordGuildRole.Prototype)
	end)

	if roleData.permissions then
		roleData.permissions = PermissionsBuilder.from(roleData.permissions)
	end

	for index, value in roleData do
		self[index] = value
	end

	return self
end

export type DiscordGuildRole = typeof(DiscordGuildRole.Prototype) & {
	discordClient: any,

	guildId: string,

	id: string,
	name: string,
	permissions: PermissionsBuilder.PermissionsBuilder,
	position: number,
	color: number,
	hoist: boolean,
	managed: boolean,
	mentionable: boolean,
}

return DiscordGuildRole.Interface
