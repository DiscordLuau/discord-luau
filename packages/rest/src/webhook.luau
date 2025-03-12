local stdPolyfills = require("../lune_packages/std_polyfills")

local future = require("../luau_packages/future")
local apiTypes = require("../lune_packages/api_types")

local request = require("./request")

--[=[
	@class Rest.webhook

	HTTP Rest API implementation for the following Resource:

	- https://discord.com/developers/docs/resources/webhook
]=]
local webhook = {}

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/webhook#create-webhook
]=]
function webhook.createWebhookAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	jsonParams: apiTypes.CreateWebhookRequest,
	auditLogReason: string?
): future.FutureLike<string, apiTypes.CreateWebhookResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(apiTypes.rest.endpoints.CreateWebhook, channelId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: any
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/webhook#get-channel-webhooks
]=]
function webhook.getChannelWebhooksAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake
): future.FutureLike<string, apiTypes.GetChannelWebhooksResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetChannelWebhooks, channelId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: any
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/webhook#get-guild-webhooks
]=]
function webhook.getGuildWebhooksAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): future.FutureLike<string, apiTypes.GetGuildWebhooksResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildWebhooks, guildId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: any
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/webhook#get-webhook
]=]
function webhook.getWebhookAsync(
	instance: request.Request,
	webhookId: apiTypes.Snowflake
): future.FutureLike<string, apiTypes.GetWebhookResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetWebhook, webhookId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: any
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/webhook#get-webhook-with-token
]=]
function webhook.getWebhookWithTokenAsync(
	instance: request.Request,
	webhookId: apiTypes.Snowflake,
	webhookToken: string
): future.FutureLike<string, apiTypes.GetWebhookWithTokenResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetWebhookWithToken, webhookId, webhookToken))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: any
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/webhook#modify-webhook
]=]
function webhook.modifyWebhookAsync(
	instance: request.Request,
	webhookId: apiTypes.Snowflake,
	jsonParams: apiTypes.ModifyWebhookRequest,
	auditLogReason: string?
): future.FutureLike<string, apiTypes.ModifyWebhookResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ModifyWebhook, webhookId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: any
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/webhook#modify-webhook-with-token
]=]
function webhook.modifyWebhookWithTokenAsync(
	instance: request.Request,
	webhookId: apiTypes.Snowflake,
	webhookToken: string,
	jsonParams: apiTypes.ModifyWebhookRequest,
	auditLogReason: string?
): future.FutureLike<string, apiTypes.ModifyWebhookWithTokenResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ModifyWebhookWithToken, webhookId, webhookToken))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: any
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/webhook#delete-webhook
]=]
function webhook.deleteWebhookAsync(
	instance: request.Request,
	webhookId: apiTypes.Snowflake,
	auditLogReason: string?
): future.FutureLike<string, apiTypes.DeleteWebhookResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.DeleteWebhook, webhookId))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: any
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/webhook#delete-webhook-with-token
]=]
function webhook.deleteWebhookWithTokenAsync(
	instance: request.Request,
	webhookId: apiTypes.Snowflake,
	webhookToken: string,
	auditLogReason: string?
): future.FutureLike<string, apiTypes.DeleteWebhookWitHTokenResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.DeleteWebhookWithToken, webhookId, webhookToken))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: any
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/webhook#execute-webhook
]=]
function webhook.executeWebhookAsync(
	instance: request.Request,
	webhookId: apiTypes.Snowflake,
	webhookToken: string,
	jsonParams: apiTypes.ExecuteWebhookRequest,
	urlParams: {
		wait: boolean?,
		threadId: apiTypes.Snowflake?,
	}
): future.FutureLike<string, apiTypes.ExecuteWebhookResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:addUrlParam("wait", urlParams.wait and tostring(urlParams.wait) or (nil :: any))
		instance:addUrlParam("thread_id", urlParams.threadId and tostring(urlParams.threadId) or (nil :: any))

		instance:setMethod("POST")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ExecuteWebhook, webhookId, webhookToken))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: any
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/webhook#get-webhook-message
]=]
function webhook.getWebhookMessageAsync(
	instance: request.Request,
	webhookId: apiTypes.Snowflake,
	webhookToken: string,
	messageId: apiTypes.Snowflake,
	urlParams: {
		threadId: apiTypes.Snowflake?,
	}
): future.FutureLike<string, apiTypes.GetWebhookMessageResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:addUrlParam("thread_id", urlParams.threadId and tostring(urlParams.threadId) or (nil :: any))

		instance:setMethod("POST")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetWebhookMessage, webhookId, webhookToken, messageId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: any
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/webhook#edit-webhook-message
]=]
function webhook.editWebhookMessageAsync(
	instance: request.Request,
	webhookId: apiTypes.Snowflake,
	webhookToken: string,
	messageId: apiTypes.Snowflake,
	jsonParams: apiTypes.EditWebhookMessageRequest,
	urlParams: {
		threadId: apiTypes.Snowflake?,
	}
): future.FutureLike<string, apiTypes.EditWebhookMessageResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:addUrlParam("thread_id", urlParams.threadId and tostring(urlParams.threadId) or (nil :: any))

		instance:setMethod("PATCH")
		instance:setUrl(string.format(apiTypes.rest.endpoints.EditWebhookMessage, webhookId, webhookToken, messageId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: any
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/webhook#delete-webhook-message
]=]
function webhook.deleteWebhookMessageAsync(
	instance: request.Request,
	webhookId: apiTypes.Snowflake,
	webhookToken: string,
	messageId: apiTypes.Snowflake,
	urlParams: {
		threadId: apiTypes.Snowflake?,
	}
): future.FutureLike<string, apiTypes.DeleteWebhookMessageResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:addUrlParam("thread_id", urlParams.threadId and tostring(urlParams.threadId) or (nil :: any))

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.EditWebhookMessage, webhookId, webhookToken, messageId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: any
end

return webhook
