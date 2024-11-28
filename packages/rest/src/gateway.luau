local async = require("../lune_packages/async")
local apiTypes = require("../lune_packages/api_types")

local request = require("./request")

--[[
	HTTP Rest API implementation for the following Resource:

	- https://discord.com/developers/docs/topics/gateway
]]
local Gateway = {}

-- https://discord.com/developers/docs/topics/gateway#get-gateway
function Gateway.getGatewayAsync(instance: request.Request): async.Async<apiTypes.GetGatewayResponse>
	return async.new(function()
		instance:setMethod("GET")
		instance:setUrl(apiTypes.rest.endpoints.GetGateway)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/topics/gateway#get-gateway-bot
function Gateway.getGatewayBotAsync(instance: request.Request): async.Async<apiTypes.GetGatewayBotResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(apiTypes.rest.endpoints.GetGatewayBot)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

return Gateway
