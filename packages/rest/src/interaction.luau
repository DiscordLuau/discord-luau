local stdPolyfills = require("../lune_packages/std_polyfills")

local async = require("../lune_packages/async")
local apiTypes = require("../lune_packages/api_types")

local request = require("./request")

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
	jsonParams: apiTypes.CreateInteractionRequest,
	urlParams: {
		withResponse: boolean?,
	}
): async.Async<apiTypes.CreateInteractionResponse>
	return async.new(function()
		instance:assertToken()

		instance:addUrlParam(
			"with_response",
			urlParams.withResponse and tostring(urlParams.withResponse) or (nil :: any)
		)

		instance:setMethod("POST")
		instance:setUrl(
			string.format(apiTypes.rest.endpoints.CreateInteractionResponse, interactionId, interactionToken)
		)
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

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
): async.Async<apiTypes.GetOriginalInteractionResponse>
	return async.new(function()
		instance:assertToken()

		instance:addUrlParam("thread_id", urlParams.threadId and tostring(urlParams.threadId) or (nil :: any))

		instance:setMethod("GET")
		instance:setUrl(
			string.format(apiTypes.rest.endpoints.GetOriginalInteractionResponse, applicationId, interactionToken)
		)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/interactions/receiving-and-responding#edit-original-interaction-response
function Interaction.editOriginalInteractionResponseAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	interactionToken: string,
	jsonParams: apiTypes.EditOriginalInteractionRequest,
	urlParams: {
		threadId: apiTypes.Snowflake?,
	}
): async.Async<apiTypes.EditOriginalInteractionResponse>
	return async.new(function()
		instance:assertToken()

		instance:addUrlParam("thread_id", urlParams.threadId and tostring(urlParams.threadId) or (nil :: any))

		instance:setMethod("PATCH")
		instance:setUrl(
			string.format(apiTypes.rest.endpoints.GetOriginalInteractionResponse, applicationId, interactionToken)
		)
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/interactions/receiving-and-responding#delete-original-interaction-response
function Interaction.deleteOriginalInteractionResponseAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	interactionToken: string
): async.Async<apiTypes.DeleteOriginalInteractionResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(
			string.format(apiTypes.rest.endpoints.DeleteOriginalInteractionResponse, applicationId, interactionToken)
		)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/interactions/receiving-and-responding#create-followup-message
function Interaction.createFollowupMessageAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	interactionToken: string,
	jsonParams: apiTypes.CreateFollowupMessageRequest,
	urlParams: {
		wait: boolean?,
		threadId: apiTypes.Snowflake?,
	}
): async.Async<apiTypes.CreateFollowupMessageResponse>
	return async.new(function()
		instance:assertToken()

		instance:addUrlParam("wait", urlParams.wait and tostring(urlParams.wait) or (nil :: any))
		instance:addUrlParam("thread_id", urlParams.threadId and tostring(urlParams.threadId) or (nil :: any))

		instance:setMethod("POST")
		instance:setUrl(string.format(apiTypes.rest.endpoints.CreateFollowupMessage, applicationId, interactionToken))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

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
): async.Async<apiTypes.GetFollowupMessageResponse>
	return async.new(function()
		instance:assertToken()

		instance:addUrlParam("thread_id", urlParams.threadId and tostring(urlParams.threadId) or (nil :: any))

		instance:setMethod("GET")
		instance:setUrl(
			string.format(apiTypes.rest.endpoints.GetFollowupMessage, applicationId, interactionToken, messageId)
		)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/interactions/receiving-and-responding#edit-followup-message
function Interaction.editFollowupMessageAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	interactionToken: string,
	messageId: apiTypes.Snowflake,
	jsonParams: apiTypes.EditFollowupMessageRequest,
	urlParams: {
		threadId: apiTypes.Snowflake?,
	}
): async.Async<apiTypes.EditFollowupMessageResponse>
	return async.new(function()
		instance:assertToken()

		instance:addUrlParam("thread_id", urlParams.threadId and tostring(urlParams.threadId) or (nil :: any))

		instance:setMethod("POST")
		instance:setUrl(
			string.format(apiTypes.rest.endpoints.EditFollowupMessage, applicationId, interactionToken, messageId)
		)
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/interactions/receiving-and-responding#delete-followup-message
function Interaction.deleteFollowupMessageAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	interactionToken: string,
	messageId: apiTypes.Snowflake
): async.Async<apiTypes.DeleteFollowupMessageResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(
			string.format(apiTypes.rest.endpoints.DeleteFollowupMessage, applicationId, interactionToken, messageId)
		)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

return Interaction
