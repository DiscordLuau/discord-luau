--[=[
	@class Builders.Guild.CommandPermission
	@__index Prototype

	Implementation of the Application Command Permission Structure as a Luau builder.

	https://discord.com/developers/docs/interactions/application-commands#application-command-permissions-object-application-command-permissions-structure
]=]

--[=[
	@prop id string?
	@within Builders.Guild.CommandPermission
	The ID of the role, user, or channel this permission applies to.
]=]

--[=[
	@prop type CommandPermissionType?
	@within Builders.Guild.CommandPermission
	Whether this permission targets a role, user, or channel.
]=]

--[=[
	@prop permission boolean
	@within Builders.Guild.CommandPermission
	Whether the target is allowed (true) or denied (false) access to the command.
]=]

local apiTypes = require("../../luau_packages/api_types")

local CommandPermission = {}

CommandPermission.Prototype = {}
CommandPermission.Interface = {}

--[=[
	@within Builders.Guild.CommandPermission

	Sets the ID of the role, user, or channel this permission applies to.
]=]
function CommandPermission.Prototype.setId(self: CommandPermission, id: apiTypes.Snowflake): CommandPermission
	self.id = id

	return self
end

--[=[
	@within Builders.Guild.CommandPermission

	Sets the type of entity this permission targets.
]=]
function CommandPermission.Prototype.setType(
	self: CommandPermission,
	permissionType: CommandPermissionType
): CommandPermission
	self.type = permissionType

	return self
end

--[=[
	@within Builders.Guild.CommandPermission

	Allows the targeted role, user, or channel to use the command.
]=]
function CommandPermission.Prototype.allow(self: CommandPermission): CommandPermission
	self.permission = true

	return self
end

--[=[
	@within Builders.Guild.CommandPermission

	Denies the targeted role, user, or channel from using the command.
]=]
function CommandPermission.Prototype.deny(self: CommandPermission): CommandPermission
	self.permission = false

	return self
end

--[=[
	@within Builders.Guild.CommandPermission

	Responsible for building the GuildApplicationCommandPermissionObject JSON that can be parsed by the Discord API.
]=]
function CommandPermission.Prototype.build(self: CommandPermission): JSON
	assert(self.id ~= nil, "CommandPermission must have an id set.")
	assert(self.type ~= nil, "CommandPermission must have a type set.")

	local typeMap: { [CommandPermissionType]: number } = {
		role = 1,
		user = 2,
		channel = 3,
	}

	return {
		id = self.id,
		type = typeMap[self.type],
		permission = self.permission,
	}
end

--[=[
	@within Builders.Guild.CommandPermission

	Responsible for creating a new CommandPermission.
]=]
function CommandPermission.Interface.new(resource: {
	id: apiTypes.Snowflake?,
	permissionType: CommandPermissionType?,
	permission: boolean?,
}?): CommandPermission
	local self = setmetatable(
		{
			permission = true,
		} :: CommandPermission,
		{
			__index = CommandPermission.Prototype,
		}
	)

	if resource then
		if resource.id then
			self:setId(resource.id)
		end

		if resource.permissionType then
			self:setType(resource.permissionType)
		end

		if resource.permission ~= nil then
			self.permission = resource.permission
		end
	end

	return self
end

export type CommandPermission = typeof(CommandPermission.Prototype) & {
	id: apiTypes.Snowflake?,
	type: CommandPermissionType?,
	permission: boolean,
}

export type JSON = typeof(CommandPermission.Prototype.build(nil :: any))

export type CommandPermissionType = "role" | "user" | "channel"
export type GuildApplicationCommandPermissionObject = apiTypes.GuildApplicationCommandPermissionObject

return CommandPermission.Interface
