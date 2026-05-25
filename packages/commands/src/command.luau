--[=[
	@class Commands.Command

	Shared type definitions for the commands framework.
]=]

local apiTypes = require("../luau_packages/api_types")
local builders = require("../luau_packages/builders")
local classes = require("../luau_packages/classes")

export type TransformFunction = (value: any, interaction: classes.TypesCommand) -> any
export type GuardFunction = (interaction: classes.TypesCommand) -> boolean
export type GuardEntry = GuardFunction | { GuardFunction }

export type SubcommandDefinition = {
	execute: (interaction: classes.TypesCommand) -> (),
	autocomplete: ((interaction: classes.Autocomplete) -> ())?,
	guards: { GuardEntry }?,
	transforms: { [string]: TransformFunction }?,
}

export type CooldownRule = { seconds: number, per: "user" | "guild" | "channel" | "member" | "global" }
export type CooldownFunction = (interaction: classes.TypesCommand) -> { CooldownRule }?

export type CommandDefinition = {
	command: builders.interactionJSON,
	execute: (interaction: classes.TypesCommand) -> (),
	userExecute: ((interaction: classes.TypesCommand, target: classes.User) -> ())?,
	messageExecute: ((interaction: classes.TypesCommand, target: classes.Message) -> ())?,
	autocomplete: ((interaction: classes.Autocomplete) -> ())?,
	components: { [string]: (interaction: classes.Component) -> () }?,
	modals: { [string]: (interaction: classes.Modal) -> () }?,
	guards: { GuardEntry }?,
	subcommands: { [string]: SubcommandDefinition | { [string]: SubcommandDefinition } }?,
	transforms: { [string]: TransformFunction }?,
	category: string?,
	nsfw: boolean?,
	cooldown: ({ CooldownRule } | CooldownFunction)?,
	maxConcurrency: { limit: number, per: "user" | "guild" | "channel" | "member" | "global" }?,
	userPermissions: { apiTypes.Permissions }?,
	clientPermissions: { apiTypes.Permissions }?,
	onCooldown: ((interaction: classes.TypesCommand, remaining: number) -> ())?,
	onConcurrencyLimited: ((interaction: classes.TypesCommand) -> ())?,
	onUserPermissionDenied: ((interaction: classes.TypesCommand, missing: { apiTypes.Permissions }) -> ())?,
	onClientPermissionDenied: ((interaction: classes.TypesCommand, missing: { apiTypes.Permissions }) -> ())?,
	onError: ((interaction: classes.TypesCommand | classes.Component | classes.Modal, errorMessage: string) -> ())?,
	onGuardFailed: ((interaction: classes.TypesCommand) -> ())?,
	afterExecute: ((interaction: classes.TypesCommand) -> ())?,
}

return {}
