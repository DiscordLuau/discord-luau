local stdPolyfills = require("../lune_packages/std_polyfills")

local future = require("../luau_packages/future")
local apiTypes = require("../lune_packages/api_types")

local request = require("./request")

--[=[
	@class Rest.interaction

	HTTP Rest API implementation for the following Resource:

	- https://discord.com/developers/docs/interactions/receiving-and-responding
]=]
local interaction = {}

--[=[
	@within Rest.application

	https://discord.com/developers/docs/interactions/receiving-and-responding#create-interaction-response
]=]
function interaction.createInteractionResponseAsync(
	instance: request.Request,
	interactionId: apiTypes.Snowflake,
	interactionToken: string,
	jsonParams: apiTypes.CreateInteractionRequest,
	urlParams: {
		withResponse: boolean?,
	}
): future.FutureLike<string, apiTypes.CreateInteractionResponse>
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

--[=[
	@within Rest.application

	https://discord.com/developers/docs/interactions/receiving-and-responding#get-original-interaction-response
]=]
function interaction.getOriginalInteractionResponseAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	interactionToken: string,
	urlParams: {
		threadId: apiTypes.Snowflake?,
	}
): future.FutureLike<
	string,
	apiTypes.GetOriginalInteractionResponse
>
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

--[=[
	@within Rest.application

	https://discord.com/developers/docs/interactions/receiving-and-responding#edit-original-interaction-response
]=]
function interaction.editOriginalInteractionResponseAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	interactionToken: string,
	jsonParams: apiTypes.EditOriginalInteractionRequest,
	urlParams: {
		threadId: apiTypes.Snowflake?,
	}
): future.FutureLike<
	string,
	apiTypes.EditOriginalInteractionResponse
>
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

--[=[
	@within Rest.application

	https://discord.com/developers/docs/interactions/receiving-and-responding#delete-original-interaction-response
]=]
function interaction.deleteOriginalInteractionResponseAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	interactionToken: string
): future.FutureLike<
	string,
	apiTypes.DeleteOriginalInteractionResponse
>
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

--[=[
	@within Rest.application

	https://discord.com/developers/docs/interactions/receiving-and-responding#create-followup-message
]=]
function interaction.createFollowupMessageAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	interactionToken: string,
	jsonParams: apiTypes.CreateFollowupMessageRequest,
	urlParams: {
		wait: boolean?,
		threadId: apiTypes.Snowflake?,
	}
): future.FutureLike<string, apiTypes.CreateFollowupMessageResponse>
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

--[=[
	@within Rest.application

	https://discord.com/developers/docs/interactions/receiving-and-responding#get-followup-message
]=]
function interaction.getFollowupMessageAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	interactionToken: string,
	messageId: apiTypes.Snowflake,
	urlParams: {
		threadId: apiTypes.Snowflake?,
	}
): future.FutureLike<string, apiTypes.GetFollowupMessageResponse>
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

--[=[
	@within Rest.application

	https://discord.com/developers/docs/interactions/receiving-and-responding#edit-followup-message
]=]
function interaction.editFollowupMessageAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	interactionToken: string,
	messageId: apiTypes.Snowflake,
	jsonParams: apiTypes.EditFollowupMessageRequest,
	urlParams: {
		threadId: apiTypes.Snowflake?,
	}
): future.FutureLike<string, apiTypes.EditFollowupMessageResponse>
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

--[=[
	@within Rest.application

	https://discord.com/developers/docs/interactions/receiving-and-responding#delete-followup-message
]=]
function interaction.deleteFollowupMessageAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	interactionToken: string,
	messageId: apiTypes.Snowflake
): future.FutureLike<string, apiTypes.DeleteFollowupMessageResponse>
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

return interaction
