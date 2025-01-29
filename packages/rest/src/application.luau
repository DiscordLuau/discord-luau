local stdPolyfills = require("../lune_packages/std_polyfills")

local future = require("../luau_packages/future")
local apiTypes = require("../lune_packages/api_types")

local request = require("./request")

--[[
	HTTP Rest API implementation for the following Resource:

	- https://discord.com/developers/docs/resources/application
]]
local Application = {}

-- https://discord.com/developers/docs/resources/application#get-current-application
function Application.getCurrentApplicationAsync(instance: request.Request, applicationId: apiTypes.Snowflake)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetCurrentApplication, applicationId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetCurrentApplicationResponse>
end

-- https://discord.com/developers/docs/resources/application#edit-current-application
function Application.editCurrentApplicationAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	jsonParams: apiTypes.EditCurrentApplicationRequest
)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(apiTypes.rest.endpoints.EditCurrentApplication, applicationId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))

		instance:executeAsync():await()
	end) :: future.FutureLike<string, apiTypes.EditCurrentApplicationResponse>
end

return Application
