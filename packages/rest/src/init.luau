local applicationRoleConnectionMetadata = require("./applicationRoleConnectionMetadata")
local invite = require("./invite")
local gateway = require("./gateway")
local emoji = require("./emoji")
local stageInstance = require("./stageInstance")
local application = require("./application")
local request = require("./request")
local autoModeration = require("./autoModeration")
local auditLog = require("./auditLog")
local voice = require("./voice")
local poll = require("./poll")

local guild = require("./guild")
local webhook = require("./webhook")
local commands = require("./commands")
local sticker = require("./sticker")
local guildTemplate = require("./guildTemplate")
local user = require("./user")
local channel = require("./channel")
local guildScheduledEvent = require("./guildScheduledEvent")
local message = require("./message")
local interaction = require("./interaction")

export type Request = request.Request

--[=[
	@class Rest

	Interface for the discord-luau Rest package

	Rest represents all possible Discord HTTP APIs, the goal for this package is to simplify the process of making a
	request to the discord API.
]=]

return {
	--[=[
		@prop interaction Rest.interaction
		@within Rest
	]=]
	interaction = interaction,

	--[=[
		@prop poll Rest.poll
		@within Rest
	]=]
	poll = poll,

	--[=[
		@prop voice Rest.voice
		@within Rest
	]=]
	voice = voice,

	--[=[
		@prop auditLog Rest.auditLog
		@within Rest
	]=]
	auditLog = auditLog,

	--[=[
		@prop autoModeration Rest.autoModeration
		@within Rest
	]=]
	autoModeration = autoModeration,

	--[=[
		@prop message Rest.message
		@within Rest
	]=]
	message = message,

	--[=[
		@prop request Rest.Request
		@within Rest
	]=]
	request = request,

	--[=[
		@prop guildScheduledEvent Rest.guildScheduledEvent
		@within Rest
	]=]
	guildScheduledEvent = guildScheduledEvent,

	--[=[
		@prop application Rest.application
		@within Rest
	]=]
	application = application,

	--[=[
		@prop channel Rest.channel
		@within Rest
	]=]
	channel = channel,

	--[=[
		@prop user Rest.user
		@within Rest
	]=]
	user = user,

	--[=[
		@prop guildTemplate Rest.guildTemplate
		@within Rest
	]=]
	guildTemplate = guildTemplate,

	--[=[
		@prop sticker Rest.sticker
		@within Rest
	]=]
	sticker = sticker,

	--[=[
		@prop commands Rest.commands
		@within Rest
	]=]
	commands = commands,

	--[=[
		@prop stageInstance Rest.stageInstance
		@within Rest
	]=]
	stageInstance = stageInstance,

	--[=[
		@prop webhook Rest.webhook
		@within Rest
	]=]
	webhook = webhook,

	--[=[
		@prop emoji Rest.emoji
		@within Rest
	]=]
	emoji = emoji,

	--[=[
		@prop gateway Rest.gateway
		@within Rest
	]=]
	gateway = gateway,

	--[=[
		@prop invite Rest.invite
		@within Rest
	]=]
	invite = invite,

	--[=[
		@prop applicationRoleConnectionMetadata Rest.applicationRoleConnectionMetadata
		@within Rest
	]=]
	applicationRoleConnectionMetadata = applicationRoleConnectionMetadata,

	--[=[
		@prop guild Rest.guild
		@within Rest
	]=]
	guild = guild,
}
