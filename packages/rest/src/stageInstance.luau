local stdPolyfills = require("../lune_packages/std_polyfills")

local future = require("../luau_packages/future")
local apiTypes = require("../lune_packages/api_types")

local request = require("./request")

--[=[
	@class Rest.stageInstance

	HTTP Rest API implementation for the following Resource:

	- https://discord.com/developers/docs/resources/stage-instance
]=]
local stageInstance = {}

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/stage-instance#create-stage-instance
]=]
function stageInstance.createStageInstanceAsync(
	instance: request.Request,
	jsonParams: apiTypes.CreateStageInstanceRequest,
	auditLogReason: string?
): future.FutureLike<string, apiTypes.CreateStageInstanceResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(apiTypes.rest.endpoints.CreateStageInstance)
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.CreateStageInstanceResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/stage-instance#get-stage-instance
]=]
function stageInstance.getStageInstanceAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake
): future.FutureLike<string, apiTypes.GetStageInstanceResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetStageInstance, channelId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetStageInstanceResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/stage-instance#modify-stage-instance
]=]
function stageInstance.modifyStageInstanceAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	jsonParams: apiTypes.ModifyStageInstanceRequest,
	auditLogReason: string?
): future.FutureLike<string, apiTypes.ModifyStageInstanceResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ModifyStageInstance, channelId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.ModifyStageInstanceResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/stage-instance#delete-stage-instance
]=]
function stageInstance.deleteStageInstanceAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake
): future.FutureLike<string, apiTypes.DeleteStageInstanceResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.DeleteStageInstance, channelId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.DeleteStageInstanceResponse>
end

return stageInstance
