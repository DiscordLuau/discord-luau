--[=[
	@class Types.application
]=]

local util = require("../luau_packages/util")

local MembershipState = table.freeze(util.tableReflect({
	Invited = 1,
	Accepted = 2,
}))

local IntegrationTypesConfig = table.freeze(util.tableReflect({
	GuildInstall = 0,
	UserInstall = 1,
}))

local ApplicationRoleConnectionMetadataType = table.freeze(util.tableReflect({
	IntegerLessThanOrEqual = 1,
	IntegerGreaterThanOrEqual = 2,
	IntegerEqual = 3,
	IntegerNotEqual = 4,
	DatetimeLessThanOrEqual = 5,
	DatetimeGreaterThanOrEqual = 6,
	BooleanEqual = 7,
	BooleanNotEqual = 8,
}))

export type MembershipState = "Invited" | "Accepted"
export type TeamRole = "Owner" | "Admin" | "Developer" | "ReadOnly"

export type IntegrationTypesConfig = "GuildInstall" | "UserInstall"

export type ApplicationRoleConnectionMetadataType =
	"IntegerLessThanOrEqual"
	| "IntegerGreaterThanOrEqual"
	| "IntegerEqual"
	| "IntegerNotEqual"
	| "DatetimeLessThanOrEqual"
	| "DatetimeGreaterThanOrEqual"
	| "BooleanEqual"
	| "BooleanNotEqual"

export type OAuth2Scopes =
	"activities.read"
	| "activities.write"
	| "applications.builds.read"
	| "applications.builds.upload"
	| "applications.commands"
	| "applications.commands.update"
	| "applications.commands.permissions.update"
	| "applications.entitlements"
	| "applications.store.update"
	| "bot"
	| "connections"
	| "dm_channels.read"
	| "email"
	| "gdm.join"
	| "guilds"
	| "guilds.join"
	| "guilds.members.read"
	| "identify"
	| "messages.read"
	| "relationships.read"
	| "role_connections.write"
	| "rpc"
	| "rpc.activities.write"
	| "rpc.notifications.read"
	| "rpc.voice.read"
	| "rpc.voice.write"
	| "voice"
	| "webhook.incoming"

return {
	MembershipState = MembershipState,
	IntegrationTypesConfig = IntegrationTypesConfig,
	ApplicationRoleConnectionMetadataType = ApplicationRoleConnectionMetadataType,
}
