--[=[
	@class Types

	Responsible for handling all types in Discord-Luau, upon requiring this module you'll have access to two things:

	- Types, for all requests, responses and iterations with the websocket, for the v10 discord API.
	- A range of enums helping to map out discord status codes, messages and other information.
		- Example, we map websocket operations so that the close code `4000` is known as `UnknownError`, which is clearer.
]=]

return {
	user = require("./user"),
	webhook = require("./webhook"),
	sticker = require("./sticker"),
	poll = require("./poll"),
	permission = require("./permission"),
	message = require("./message"),
	interaction = require("./interaction"),
	guild = require("./guild"),
	entitlement = require("./entitlement"),
	embed = require("./embed"),
	channel = require("./channel"),
	application = require("./application"),
	apiTypes = require("./apiTypes"),
	client = require("./client"),
	voice = {},
	rest = {
		endpoints = require("./rest/endpoints"),
		types = require("./rest/types"),
	},
	gateway = {
		closeCodes = require("./gateway/closeCodes"),
		intents = require("./gateway/intents"),
		opcodes = require("./gateway/opcodes"),
		receiveEvents = require("./gateway/receiveEvents"),
		sendEvents = require("./gateway/sendEvents"),
		types = require("./gateway/types"),
	},
}
