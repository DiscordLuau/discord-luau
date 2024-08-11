local serde = require("@std-polyfills/serde")

local request = require("@rest/request")
local future = require("@vendor/future")

local restTypes = require("@api-types/rest/types")
local apiTypes = require("@api-types/apiTypes")
local restEndpoints = require("@api-types/rest/endpoints")

--[[
	HTTP Rest API implementation for the following Resource:

	- https://discord.com/developers/docs/resources/stage-instance
]]
local StageInstance = {}

-- https://discord.com/developers/docs/resources/stage-instance#create-stage-instance
function StageInstance.createStageInstanceAsync(
	instance: request.Request,
	jsonParams: restTypes.CreateStageInstanceRequest,
	auditLogReason: string?
): future.Future<restTypes.CreateStageInstanceResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(restEndpoints.CreateStageInstance)
		instance:setBody(serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/stage-instance#get-stage-instance
function StageInstance.getStageInstanceAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake
): future.Future<restTypes.GetStageInstanceResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.GetStageInstance, channelId))

		local response = instance:executeAsync():await()

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/stage-instance#modify-stage-instance
function StageInstance.modifyStageInstanceAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	jsonParams: restTypes.ModifyStageInstanceRequest,
	auditLogReason: string?
): future.Future<restTypes.ModifyStageInstanceResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(restEndpoints.ModifyStageInstance, channelId))
		instance:setBody(serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/stage-instance#delete-stage-instance
function StageInstance.deleteStageInstanceAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake
): future.Future<restTypes.DeleteStageInstanceResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(restEndpoints.DeleteStageInstance, channelId))

		local response = instance:executeAsync():await()

		return response.body
	end)
end

return StageInstance
