local request = require("@rest/request")
local future = require("@vendor/future")

local restTypes = require("@api-types/rest/types")
local restEndpoints = require("@api-types/rest/endpoints")

--[[
	HTTP Rest API implementation for the following Resource:

	- https://discord.com/developers/docs/topics/gateway
]]
local Gateway = {}

-- https://discord.com/developers/docs/topics/gateway#get-gateway
function Gateway.getGatewayAsync(instance: request.Request): future.Future<restTypes.GetGatewayResponse>
	return future.new(function()
		instance:setMethod("GET")
		instance:setUrl(restEndpoints.GetGateway)

		local response = instance:executeAsync():await()

		return response.body
	end)
end

-- https://discord.com/developers/docs/topics/gateway#get-gateway-bot
function Gateway.getGatewayBotAsync(instance: request.Request): future.Future<restTypes.GetGatewayBotResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(restEndpoints.GetGatewayBot)

		local response = instance:executeAsync():await()

		return response.body
	end)
end

return Gateway
