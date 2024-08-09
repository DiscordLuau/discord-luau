local serde = require("@std-polyfills/serde")

local request = require("@rest/request")
local future = require("@vendor/future")

local restTypes = require("@api-types/rest/types")
local restEndpoints = require("@api-types/rest/endpoints")

local Application = {}

-- https://discord.com/developers/docs/resources/application#get-current-application
function Application.getCurrentApplicationnAsync(
	instance: request.Request
): future.Future<restTypes.GetCurrentApplicationResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(restEndpoints.GetCurrentApplication)

		local response = instance:executeAsync():await()

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/application#edit-current-application
function Application.editCurrentApplicationnAsync(
	instance: request.Request,
	jsonParams: restTypes.EditCurrentApplicationRequest
): future.Future<nil>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(restEndpoints.EditCurrentApplication)
		instance:setBody(serde.encode("json", jsonParams, true))

		instance:executeAsync():await()
	end)
end

return Application
