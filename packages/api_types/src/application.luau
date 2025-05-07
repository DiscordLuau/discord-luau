--[=[
	@class Types.application
]=]

local util = require("../lune_packages/util")

local MembershipState = table.freeze(util.tableReflect({
	Invited = 1,
	Accepted = 2,
}))

local IntegrationTypesConfig = table.freeze(util.tableReflect({
	GuildInstall = 0,
	UserInstall = 1,
}))

export type MembershipState = "Invited" | "Accepted"
export type TeamRole = "Owner" | "Admin" | "Developer" | "ReadOnly"

export type IntegrationTypesConfig = "GuildInstall" | "UserInstall"

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
}
