local future = require("@vendor/future")
local logger = require("@vendor/logger")

local gateway = require("@rest/gateway")

local state = require("@classes/state")

local DISCORD_VERSION = 10

local Bot = {}

Bot.Interface = {}
Bot.Prototype = {}

function Bot.Prototype.queryGatewayInformation(self: Bot)
	return future.new(function()
		local request = self.state.rest:newRequest()

		local status, response = gateway.getGatewayBotAsync(request):await()

		assert(status == "Fulfilled", response)

		return response
	end)
end

function Bot.Prototype.connectAsync(self: Bot)
	return future.new(function()
		local status, gatewayInformation = self:queryGatewayInformation():await()

		assert(status == "Fulfilled", gatewayInformation)

		self.state.webSocketManager:connectAsync(gatewayInformation):await()
	end)
end

function Bot.Interface.new(options: {
	token: string,
	intents: number,
})
	local self = setmetatable(
		{
			state = state.new(options.token, options.intents, DISCORD_VERSION),
			logger = logger.new("Bot"),
		} :: Bot,
		{ __index = Bot.Prototype }
	)

	return self
end

export type Bot = typeof(Bot.Prototype) & {
	state: state.State,
	logger: logger.Logger,
}

return Bot.Interface
