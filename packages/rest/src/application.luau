local serde = require("@std-polyfills/serde")

local request = require("@rest/request")
local future = require("@vendor/future")

local restTypes = require("@api-types/rest/types")
local apiTypes = require("@api-types/apiTypes")
local restEndpoints = require("@api-types/rest/endpoints")

--[[
	HTTP Rest API implementation for the following Resource:

	- https://discord.com/developers/docs/resources/application
]]
local Application = {}

-- https://discord.com/developers/docs/resources/application#get-current-application
function Application.getCurrentApplicationAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake
): future.Future<restTypes.GetCurrentApplicationResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.GetCurrentApplication, applicationId))

		local response = instance:executeAsync():await()

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/application#edit-current-application
function Application.editCurrentApplicationAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	jsonParams: restTypes.EditCurrentApplicationRequest
): future.Future<nil>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(restEndpoints.EditCurrentApplication, applicationId))
		instance:setBody(serde.encode("json", jsonParams, true))

		instance:executeAsync():await()
	end)
end

return Application
