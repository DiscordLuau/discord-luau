local future = require("../luau_packages/future")
local apiTypes = require("../lune_packages/api_types")

local request = require("./request")

--[=[
	@class Rest.gateway

	HTTP Rest API implementation for the following Resource:

	- https://discord.com/developers/docs/topics/gateway
]=]
local gateway = {}

--[=[
	@within Rest.application

	https://discord.com/developers/docs/topics/gateway#get-gateway
]=]
function gateway.getGatewayAsync(instance: request.Request): future.FutureLike<string, apiTypes.GetGatewayResponse>
	return future.Future.new(function()
		instance:setMethod("GET")
		instance:setUrl(apiTypes.rest.endpoints.GetGateway)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetGatewayResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/topics/gateway#get-gateway-bot
]=]
function gateway.getGatewayBotAsync(
	instance: request.Request
): future.FutureLike<string, apiTypes.GetGatewayBotResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(apiTypes.rest.endpoints.GetGatewayBot)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetGatewayBotResponse>
end

return gateway
