local net = require("@lune/net")

local manager = require("@websocket/manager")

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

instance:connectAsync(net.jsonDecode(info.body)):await()
