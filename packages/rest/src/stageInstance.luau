local stdPolyfills = require("../lune_packages/std_polyfills")

local async = require("../lune_packages/async")
local apiTypes = require("../lune_packages/api_types")

local request = require("./request")

--[[
	HTTP Rest API implementation for the following Resource:

	- https://discord.com/developers/docs/resources/stage-instance
]]
local StageInstance = {}

-- https://discord.com/developers/docs/resources/stage-instance#create-stage-instance
function StageInstance.createStageInstanceAsync(
	instance: request.Request,
	jsonParams: apiTypes.CreateStageInstanceRequest,
	auditLogReason: string?
): async.Async<apiTypes.CreateStageInstanceResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(apiTypes.rest.endpoints.CreateStageInstance)
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/stage-instance#get-stage-instance
function StageInstance.getStageInstanceAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake
): async.Async<apiTypes.GetStageInstanceResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetStageInstance, channelId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/stage-instance#modify-stage-instance
function StageInstance.modifyStageInstanceAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	jsonParams: apiTypes.ModifyStageInstanceRequest,
	auditLogReason: string?
): async.Async<apiTypes.ModifyStageInstanceResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ModifyStageInstance, channelId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/stage-instance#delete-stage-instance
function StageInstance.deleteStageInstanceAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake
): async.Async<apiTypes.DeleteStageInstanceResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.DeleteStageInstance, channelId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

return StageInstance
