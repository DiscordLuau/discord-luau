local util = require("../lune_packages/util")

local InteractionType = table.freeze(util.table.reflect({
	Ping = 1,
	ApplicationCommand = 2,
	MessageComponent = 3,
	ApplicationCommandAutocomplete = 4,
	ModalSubmit = 5,
}))

local ApplicationCommandOptionType = table.freeze(util.table.reflect({
	SubCommand = 1,
	SubCommandGroup = 2,
	String = 3,
	Integer = 4,
	Boolean = 5,
	User = 6,
	Channel = 7,
	Role = 8,
	Mentionable = 9,
	Number = 10,
	Attachment = 11,
}))

local InteractionContextType = table.freeze(util.table.reflect({
	Guild = 0,
	BotDm = 1,
	PrivateChannel = 2,
}))

local ApplicationCommandType = table.freeze(util.table.reflect({
	ChatInput = 1,
	User = 2,
	Message = 3,
	PrimaryEntryPoiant = 4,
}))

local ComponentTypes = table.freeze(util.table.reflect({
	ActionRow = 1,
	Button = 2,
	StringSelect = 3,
	TextInput = 4,
	UserSelect = 5,
	RoleSelect = 6,
	MentionableSelect = 7,
	ChannelSelect = 8,
}))

export type InteractionType =
	"Ping"
	| "ApplicationCommand"
	| "MessageComponent"
	| "ApplicationCommandAutocomplete"
	| "ModalSubmit"

export type ComponentTypes =
	"ActionRow"
	| "Button"
	| "StringSelect"
	| "TextInput"
	| "UserSelect"
	| "RoleSelect"
	| "MentionableSelect"
	| "ChannelSelect"

export type ApplicationCommandOptionType =
	"SubCommand"
	| "SubCommandGroup"
	| "String"
	| "Integer"
	| "Boolean"
	| "User"
	| "Channel"
	| "Role"
	| "Mentionable"
	| "Number"
	| "Attachment"

export type ApplicationCommandType = "ChatInput" | "User" | "Message" | "PrimaryEntryPoiant"

export type InteractionContextType = "Guild" | "BotDm" | "PrivateChannel"

return {
	InteractionType = InteractionType,
	ApplicationCommandOptionType = ApplicationCommandOptionType,
	InteractionContextType = InteractionContextType,
	ApplicationCommandType = ApplicationCommandType,
	ComponentTypes = ComponentTypes,
}
