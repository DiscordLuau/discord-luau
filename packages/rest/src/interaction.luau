local serde = require("@std-polyfills/serde")

local request = require("@rest/request")
local future = require("@vendor/future")

local restTypes = require("@api-types/rest/types")
local apiTypes = require("@api-types/apiTypes")
local restEndpoints = require("@api-types/rest/endpoints")

--[[
	HTTP Rest API implementation for the following Resource:

	- https://discord.com/developers/docs/interactions/receiving-and-responding
]]
local Interaction = {}

-- https://discord.com/developers/docs/interactions/receiving-and-responding#create-interaction-response
function Interaction.createInteractionResponseAsync(
	instance: request.Request,
	interactionId: apiTypes.Snowflake,
	interactionToken: string,
	jsonParams: restTypes.CreateInteractionRequest
): future.Future<restTypes.CreateInteractionResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(restEndpoints.CreateInteractionResponse, interactionId, interactionToken))
		instance:setBody(serde.encode("json", jsonParams, true))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/interactions/receiving-and-responding#get-original-interaction-response
function Interaction.getOriginalInteractionResponseAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	interactionToken: string,
	urlParams: {
		threadId: apiTypes.Snowflake?,
	}
): future.Future<restTypes.GetOriginalInteractionResponse>
	return future.new(function()
		instance:assertToken()

		instance:addUrlParam("thread_id", urlParams.threadId and tostring(urlParams.threadId) or (nil :: any))

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.GetOriginalInteractionResponse, applicationId, interactionToken))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/interactions/receiving-and-responding#edit-original-interaction-response
function Interaction.editOriginalInteractionResponseAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	interactionToken: string,
	jsonParams: restTypes.EditOriginalInteractionRequest,
	urlParams: {
		threadId: apiTypes.Snowflake?,
	}
): future.Future<restTypes.EditOriginalInteractionResponse>
	return future.new(function()
		instance:assertToken()

		instance:addUrlParam("thread_id", urlParams.threadId and tostring(urlParams.threadId) or (nil :: any))

		instance:setMethod("PATCH")
		instance:setUrl(string.format(restEndpoints.GetOriginalInteractionResponse, applicationId, interactionToken))
		instance:setBody(serde.encode("json", jsonParams, true))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/interactions/receiving-and-responding#delete-original-interaction-response
function Interaction.deleteOriginalInteractionResponseAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	interactionToken: string
): future.Future<restTypes.DeleteOriginalInteractionResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(restEndpoints.DeleteOriginalInteractionResponse, applicationId, interactionToken))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/interactions/receiving-and-responding#create-followup-message
function Interaction.createFollowupMessageAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	interactionToken: string,
	jsonParams: restTypes.CreateFollowupMessageRequest,
	urlParams: {
		wait: boolean?,
		threadId: apiTypes.Snowflake?,
	}
): future.Future<restTypes.CreateFollowupMessageResponse>
	return future.new(function()
		instance:assertToken()

		instance:addUrlParam("wait", urlParams.wait and tostring(urlParams.wait) or (nil :: any))
		instance:addUrlParam("thread_id", urlParams.threadId and tostring(urlParams.threadId) or (nil :: any))

		instance:setMethod("POST")
		instance:setUrl(string.format(restEndpoints.CreateFollowupMessage, applicationId, interactionToken))
		instance:setBody(serde.encode("json", jsonParams, true))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/interactions/receiving-and-responding#get-followup-message
function Interaction.getFollowupMessageAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	interactionToken: string,
	messageId: apiTypes.Snowflake,
	urlParams: {
		threadId: apiTypes.Snowflake?,
	}
): future.Future<restTypes.GetFollowupMessageResponse>
	return future.new(function()
		instance:assertToken()

		instance:addUrlParam("thread_id", urlParams.threadId and tostring(urlParams.threadId) or (nil :: any))

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.GetFollowupMessage, applicationId, interactionToken, messageId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/interactions/receiving-and-responding#edit-followup-message
function Interaction.editFollowupMessageAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	interactionToken: string,
	messageId: apiTypes.Snowflake,
	jsonParams: restTypes.EditFollowupMessageRequest,
	urlParams: {
		threadId: apiTypes.Snowflake?,
	}
): future.Future<restTypes.EditFollowupMessageResponse>
	return future.new(function()
		instance:assertToken()

		instance:addUrlParam("thread_id", urlParams.threadId and tostring(urlParams.threadId) or (nil :: any))

		instance:setMethod("POST")
		instance:setUrl(string.format(restEndpoints.EditFollowupMessage, applicationId, interactionToken, messageId))
		instance:setBody(serde.encode("json", jsonParams, true))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/interactions/receiving-and-responding#delete-followup-message
function Interaction.deleteFollowupMessageAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	interactionToken: string,
	messageId: apiTypes.Snowflake
): future.Future<restTypes.DeleteFollowupMessageResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(restEndpoints.DeleteFollowupMessage, applicationId, interactionToken, messageId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

return Interaction
