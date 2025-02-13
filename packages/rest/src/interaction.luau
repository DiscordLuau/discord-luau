local stdPolyfills = require("../lune_packages/std_polyfills")

local future = require("../luau_packages/future")
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
)
	return future.Future.new(function()
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

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.CreateInteractionResponse>
end

-- https://discord.com/developers/docs/interactions/receiving-and-responding#get-original-interaction-response
function Interaction.getOriginalInteractionResponseAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	interactionToken: string,
	urlParams: {
		threadId: apiTypes.Snowflake?,
	}
)
	return future.Future.new(function()
		instance:assertToken()

		instance:addUrlParam("thread_id", urlParams.threadId and tostring(urlParams.threadId) or (nil :: any))

		instance:setMethod("GET")
		instance:setUrl(
			string.format(apiTypes.rest.endpoints.GetOriginalInteractionResponse, applicationId, interactionToken)
		)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetOriginalInteractionResponse>
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
)
	return future.Future.new(function()
		instance:assertToken()

		instance:addUrlParam("thread_id", urlParams.threadId and tostring(urlParams.threadId) or (nil :: any))

		instance:setMethod("PATCH")
		instance:setUrl(
			string.format(apiTypes.rest.endpoints.GetOriginalInteractionResponse, applicationId, interactionToken)
		)
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.EditOriginalInteractionResponse>
end

-- https://discord.com/developers/docs/interactions/receiving-and-responding#delete-original-interaction-response
function Interaction.deleteOriginalInteractionResponseAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	interactionToken: string
)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(
			string.format(apiTypes.rest.endpoints.DeleteOriginalInteractionResponse, applicationId, interactionToken)
		)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.DeleteOriginalInteractionResponse>
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
)
	return future.Future.new(function()
		instance:assertToken()

		instance:addUrlParam("wait", urlParams.wait and tostring(urlParams.wait) or (nil :: any))
		instance:addUrlParam("thread_id", urlParams.threadId and tostring(urlParams.threadId) or (nil :: any))

		instance:setMethod("POST")
		instance:setUrl(string.format(apiTypes.rest.endpoints.CreateFollowupMessage, applicationId, interactionToken))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.CreateFollowupMessageResponse>
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
)
	return future.Future.new(function()
		instance:assertToken()

		instance:addUrlParam("thread_id", urlParams.threadId and tostring(urlParams.threadId) or (nil :: any))

		instance:setMethod("GET")
		instance:setUrl(
			string.format(apiTypes.rest.endpoints.GetFollowupMessage, applicationId, interactionToken, messageId)
		)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetFollowupMessageResponse>
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
)
	return future.Future.new(function()
		instance:assertToken()

		instance:addUrlParam("thread_id", urlParams.threadId and tostring(urlParams.threadId) or (nil :: any))

		instance:setMethod("POST")
		instance:setUrl(
			string.format(apiTypes.rest.endpoints.EditFollowupMessage, applicationId, interactionToken, messageId)
		)
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.EditFollowupMessageResponse>
end

-- https://discord.com/developers/docs/interactions/receiving-and-responding#delete-followup-message
function Interaction.deleteFollowupMessageAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	interactionToken: string,
	messageId: apiTypes.Snowflake
)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(
			string.format(apiTypes.rest.endpoints.DeleteFollowupMessage, applicationId, interactionToken, messageId)
		)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.DeleteFollowupMessageResponse>
end

return Interaction
