local net = require("@lune/net")

local manager = require("@websocket/manager")
local logger = require("@vendor/logger")

local gatewayTypes = require("@api-types/gateway/types")

local DISCORD_BOT_TOKEN = ""

local instance = manager.new({
	token = DISCORD_BOT_TOKEN,
	intents = 512,
	webSocketVersion = 10,
})

local info = net.request({
	url = "https://discord.com/api/gateway/bot",
	headers = {
		["authorization"] = `Bot {DISCORD_BOT_TOKEN}`,
		["content-type"] = "application/json",
	},
	method = "GET",
})

local loggerObject = logger.new("development")

loggerObject:info(`Requesting connect!`)

instance:connectAsync(net.jsonDecode(info.body)):await()

instance.onAllShardsReady:listenOnce(function(data)
	local payload = data.payload :: gatewayTypes.ReadyPayload

	loggerObject:info(`All shards are Ready! Logged in as: {payload.d.user.username}#{payload.d.user.discriminator}`)
end)
