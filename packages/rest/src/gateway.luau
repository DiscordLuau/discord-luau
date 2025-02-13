local future = require("../luau_packages/future")
local apiTypes = require("../lune_packages/api_types")

local request = require("./request")

--[[
	HTTP Rest API implementation for the following Resource:

	- https://discord.com/developers/docs/topics/gateway
]]
local Gateway = {}

-- https://discord.com/developers/docs/topics/gateway#get-gateway
function Gateway.getGatewayAsync(instance: request.Request)
	return future.Future.new(function()
		instance:setMethod("GET")
		instance:setUrl(apiTypes.rest.endpoints.GetGateway)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetGatewayResponse>
end

-- https://discord.com/developers/docs/topics/gateway#get-gateway-bot
function Gateway.getGatewayBotAsync(instance: request.Request)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(apiTypes.rest.endpoints.GetGatewayBot)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetGatewayBotResponse>
end

return Gateway
