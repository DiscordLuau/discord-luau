return {
	BotGateway = "gateway/bot",

	BotGetGuild = "guilds/%s",
	BotGetChannel = "channels/%s",
	BotCreateMessage = "channels/%s/messages",

	CreateGlobalApplicationCommand = "applications/%s/commands",
	EditGlobalApplicationCommand = "applications/%s/commands/%s",
	GetGlobalApplicationCommands = "applications/%s/commands",
	GetGlobalApplicationCommand = "applications/%s/commands/%s",
	DeleteGlobalApplicationCommand = "applications/%s/commands/%s",

	CreateGuildApplicationCommand = "applications/%s/guilds/%s/commands",
	EditGuildApplicationCommand = "applications/%s/guilds/%s/commands/%s",
	GetGuildApplicationCommands = "applications/%s/guilds/%s/commands",
	GetGuildApplicationCommand = "applications/%s/guilds/%s/commands/%s",
	DeleteGuildApplicationCommand = "applications/%s/guilds/%s/commands/%s",

	CreateInteractionResponse = "interactions/%s/%s/callback",
	EditOriginalInteractionResponse = "webhooks/%s/%s/messages/@original",
}