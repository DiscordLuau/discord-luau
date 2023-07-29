local DiscordLuaU = {}

DiscordLuaU.Internal = {}
DiscordLuaU.Interface = {
	Internal = DiscordLuaU.Internal,

	UI = {}
}

DiscordLuaU.Interface.UI.ActionRowComponent = require("Classes/Components/ActionRowComponent")
DiscordLuaU.Interface.UI.ButtonComponent = require("Classes/Components/ButtonComponent")
DiscordLuaU.Interface.UI.SelectionComponent = require("Classes/Components/SelectionComponent")
DiscordLuaU.Interface.UI.TextInputComponent = require("Classes/Components/TextInputComponent")

DiscordLuaU.Interface.DiscordClient = require("Classes/DiscordClient")
DiscordLuaU.Interface.DiscordIntents = require("Classes/DiscordIntents")
DiscordLuaU.Interface.DiscordPresence = require("Classes/DiscordPresence")
DiscordLuaU.Interface.DiscordActivity = require("Classes/DiscordActivity")
DiscordLuaU.Interface.DiscordSettings = require("Classes/DiscordSettings")
DiscordLuaU.Interface.DiscordEmbed = require("Classes/DiscordEmbed")
DiscordLuaU.Interface.DiscordMessage = require("Classes/DiscordMessage")
DiscordLuaU.Interface.DiscordPermissions = require("Classes/DiscordPermissions")

DiscordLuaU.Interface.DiscordModal = require("Classes/DiscordModal")

DiscordLuaU.Interface.ApplicationCommand = require("Classes/ApplicationCommand")
DiscordLuaU.Interface.ApplicationCommandOptions = require("Classes/ApplicationCommandOptions")

return DiscordLuaU.Interface
