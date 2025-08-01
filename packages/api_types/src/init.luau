--[=[
	@class Types

	Responsible for handling all types in Discord-Luau, upon requiring this module you'll have access to two things:

	- Types, for all requests, responses and iterations with the websocket, for the v10 discord API.
	- A range of enums helping to map out discord status codes, messages and other information.
		- Example, we map websocket operations so that the close code `4000` is known as `UnknownError`, which is clearer.
]=]

return {
	user = require("@self/user"),
	webhook = require("@self/webhook"),
	sticker = require("@self/sticker"),
	poll = require("@self/poll"),
	permission = require("@self/permission"),
	message = require("@self/message"),
	interaction = require("@self/interaction"),
	guild = require("@self/guild"),
	entitlement = require("@self/entitlement"),
	embed = require("@self/embed"),
	channel = require("@self/channel"),
	application = require("@self/application"),
	apiTypes = require("@self/apiTypes"),
	client = require("@self/client"),
	voice = {},
	rest = {
		endpoints = require("@self/rest/endpoints"),
		types = require("@self/rest/types"),
	},
	gateway = {
		closeCodes = require("@self/gateway/closeCodes"),
		intents = require("@self/gateway/intents"),
		opcodes = require("@self/gateway/opcodes"),
		receiveEvents = require("@self/gateway/receiveEvents"),
		sendEvents = require("@self/gateway/sendEvents"),
		types = require("@self/gateway/types"),
	},
}
