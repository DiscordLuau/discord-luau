local stdPolyfills = require("../lune_packages/std_polyfills")

local async = require("../lune_packages/async")
local apiTypes = require("../lune_packages/api_types")

local request = require("./request")

--[[
	HTTP Rest API implementation for the following Resource:

	- https://discord.com/developers/docs/resources/application
]]
local Application = {}

-- https://discord.com/developers/docs/resources/application#get-current-application
function Application.getCurrentApplicationAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake
): async.Async<apiTypes.GetCurrentApplicationResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetCurrentApplication, applicationId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/application#edit-current-application
function Application.editCurrentApplicationAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	jsonParams: apiTypes.EditCurrentApplicationRequest
): async.Async<nil>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(apiTypes.rest.endpoints.EditCurrentApplication, applicationId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))

		instance:executeAsync():await()
	end)
end

return Application
