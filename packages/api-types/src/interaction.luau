export type InteractionType =
	"Ping"
	| "ApplicationCommand"
	| "MessageComponent"
	| "ApplicationCommandAutocomplete"
	| "ModalSubmit"

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

export type InteractionContextType = "Guild" | "BotDm" | "PrivateChannel"

return "DISCORD_V10_INTERACTION_TYPES"
