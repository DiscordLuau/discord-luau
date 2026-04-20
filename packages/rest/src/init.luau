local applicationRoleConnectionMetadata = require("@self/applicationRoleConnectionMetadata")
local invite = require("@self/invite")
local gateway = require("@self/gateway")
local emoji = require("@self/emoji")
local stageInstance = require("@self/stageInstance")
local application = require("@self/application")
local request = require("@self/request")
local autoModeration = require("@self/autoModeration")
local auditLog = require("@self/auditLog")
local voice = require("@self/voice")
local poll = require("@self/poll")

local guild = require("@self/guild")
local webhook = require("@self/webhook")
local commands = require("@self/commands")
local sticker = require("@self/sticker")
local guildTemplate = require("@self/guildTemplate")
local user = require("@self/user")
local channel = require("@self/channel")
local guildScheduledEvent = require("@self/guildScheduledEvent")
local message = require("@self/message")
local interaction = require("@self/interaction")

export type Request = request.Request

--[=[
	@class Rest

	Interface for the discord-luau Rest package

	Rest represents all possible Discord HTTP APIs, the goal for this package is to simplify the process of making a
	request to the discord API.
]=]

--[=[
	@prop interaction Rest.interaction
	@within Rest
]=]

--[=[
	@prop poll Rest.poll
	@within Rest
]=]

--[=[
	@prop voice Rest.voice
	@within Rest
]=]

--[=[
	@prop auditLog Rest.auditLog
	@within Rest
]=]

--[=[
	@prop autoModeration Rest.autoModeration
	@within Rest
]=]

--[=[
	@prop message Rest.message
	@within Rest
]=]

--[=[
	@prop request Rest.Request
	@within Rest
]=]

--[=[
	@prop guildScheduledEvent Rest.guildScheduledEvent
	@within Rest
]=]

--[=[
	@prop application Rest.application
	@within Rest
]=]

--[=[
	@prop channel Rest.channel
	@within Rest
]=]

--[=[
	@prop user Rest.user
	@within Rest
]=]

--[=[
	@prop guildTemplate Rest.guildTemplate
	@within Rest
]=]

--[=[
	@prop sticker Rest.sticker
	@within Rest
]=]

--[=[
	@prop commands Rest.commands
	@within Rest
]=]

--[=[
	@prop stageInstance Rest.stageInstance
	@within Rest
]=]

--[=[
	@prop webhook Rest.webhook
	@within Rest
]=]

--[=[
	@prop emoji Rest.emoji
	@within Rest
]=]

--[=[
	@prop gateway Rest.gateway
	@within Rest
]=]

--[=[
	@prop invite Rest.invite
	@within Rest
]=]

--[=[
	@prop applicationRoleConnectionMetadata Rest.applicationRoleConnectionMetadata
	@within Rest
]=]

--[=[
	@prop guild Rest.guild
	@within Rest
]=]

return {
	interaction = interaction,

	poll = poll,

	voice = voice,

	auditLog = auditLog,

	autoModeration = autoModeration,

	message = message,

	request = request,

	guildScheduledEvent = guildScheduledEvent,

	application = application,

	channel = channel,

	user = user,

	guildTemplate = guildTemplate,

	sticker = sticker,

	commands = commands,

	stageInstance = stageInstance,

	webhook = webhook,

	emoji = emoji,

	gateway = gateway,

	invite = invite,

	applicationRoleConnectionMetadata = applicationRoleConnectionMetadata,

	guild = guild,
}
