local stdPolyfills = require("../lune_packages/std_polyfills")

local future = require("../luau_packages/future")
local apiTypes = require("../lune_packages/api_types")

local request = require("./request")

--[[
	HTTP Rest API implementation for the following Resource:

	- https://discord.com/developers/docs/resources/webhook
]]
local Webhook = {}

-- https://discord.com/developers/docs/resources/webhook#create-webhook
function Webhook.createWebhookAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	jsonParams: apiTypes.CreateWebhookRequest,
	auditLogReason: string?
)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(apiTypes.rest.endpoints.CreateWebhook, channelId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.CreateWebhookResponse>
end

-- https://discord.com/developers/docs/resources/webhook#get-channel-webhooks
function Webhook.getChannelWebhooksAsync(instance: request.Request, channelId: apiTypes.Snowflake)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetChannelWebhooks, channelId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetChannelWebhooksResponse>
end

-- https://discord.com/developers/docs/resources/webhook#get-guild-webhooks
function Webhook.getGuildWebhooksAsync(instance: request.Request, guildId: apiTypes.Snowflake)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildWebhooks, guildId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetGuildWebhooksResponse>
end

-- https://discord.com/developers/docs/resources/webhook#get-webhook
function Webhook.getWebhookAsync(instance: request.Request, webhookId: apiTypes.Snowflake)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetWebhook, webhookId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetWebhookResponse>
end

-- https://discord.com/developers/docs/resources/webhook#get-webhook-with-token
function Webhook.getWebhookWithTokenAsync(
	instance: request.Request,
	webhookId: apiTypes.Snowflake,
	webhookToken: string
)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetWebhookWithToken, webhookId, webhookToken))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetWebhookWithTokenResponse>
end

-- https://discord.com/developers/docs/resources/webhook#modify-webhook
function Webhook.modifyWebhookAsync(
	instance: request.Request,
	webhookId: apiTypes.Snowflake,
	jsonParams: apiTypes.ModifyWebhookRequest,
	auditLogReason: string?
)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ModifyWebhook, webhookId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.ModifyWebhookResponse>
end

-- https://discord.com/developers/docs/resources/webhook#modify-webhook-with-token
function Webhook.modifyWebhookWithTokenAsync(
	instance: request.Request,
	webhookId: apiTypes.Snowflake,
	webhookToken: string,
	jsonParams: apiTypes.ModifyWebhookRequest,
	auditLogReason: string?
)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ModifyWebhookWithToken, webhookId, webhookToken))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.ModifyWebhookWithTokenResponse>
end

-- https://discord.com/developers/docs/resources/webhook#delete-webhook
function Webhook.deleteWebhookAsync(instance: request.Request, webhookId: apiTypes.Snowflake, auditLogReason: string?)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.DeleteWebhook, webhookId))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.DeleteWebhookResponse>
end

-- https://discord.com/developers/docs/resources/webhook#delete-webhook-with-token
function Webhook.deleteWebhookWithTokenAsync(
	instance: request.Request,
	webhookId: apiTypes.Snowflake,
	webhookToken: string,
	auditLogReason: string?
)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.DeleteWebhookWithToken, webhookId, webhookToken))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.DeleteWebhookWitHTokenResponse>
end

-- https://discord.com/developers/docs/resources/webhook#execute-webhook
function Webhook.executeWebhookAsync(
	instance: request.Request,
	webhookId: apiTypes.Snowflake,
	webhookToken: string,
	jsonParams: apiTypes.ExecuteWebhookRequest,
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
		instance:setUrl(string.format(apiTypes.rest.endpoints.ExecuteWebhook, webhookId, webhookToken))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.ExecuteWebhookResponse>
end

-- https://discord.com/developers/docs/resources/webhook#get-webhook-message
function Webhook.getWebhookMessageAsync(
	instance: request.Request,
	webhookId: apiTypes.Snowflake,
	webhookToken: string,
	messageId: apiTypes.Snowflake,
	urlParams: {
		threadId: apiTypes.Snowflake?,
	}
)
	return future.Future.new(function()
		instance:assertToken()

		instance:addUrlParam("thread_id", urlParams.threadId and tostring(urlParams.threadId) or (nil :: any))

		instance:setMethod("POST")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetWebhookMessage, webhookId, webhookToken, messageId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetWebhookMessageResponse>
end

-- https://discord.com/developers/docs/resources/webhook#edit-webhook-message
function Webhook.editWebhookMessageAsync(
	instance: request.Request,
	webhookId: apiTypes.Snowflake,
	webhookToken: string,
	messageId: apiTypes.Snowflake,
	jsonParams: apiTypes.EditWebhookMessageRequest,
	urlParams: {
		threadId: apiTypes.Snowflake?,
	}
)
	return future.Future.new(function()
		instance:assertToken()

		instance:addUrlParam("thread_id", urlParams.threadId and tostring(urlParams.threadId) or (nil :: any))

		instance:setMethod("PATCH")
		instance:setUrl(string.format(apiTypes.rest.endpoints.EditWebhookMessage, webhookId, webhookToken, messageId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.EditWebhookMessageResponse>
end

-- https://discord.com/developers/docs/resources/webhook#delete-webhook-message
function Webhook.deleteWebhookMessageAsync(
	instance: request.Request,
	webhookId: apiTypes.Snowflake,
	webhookToken: string,
	messageId: apiTypes.Snowflake,
	urlParams: {
		threadId: apiTypes.Snowflake?,
	}
)
	return future.Future.new(function()
		instance:assertToken()

		instance:addUrlParam("thread_id", urlParams.threadId and tostring(urlParams.threadId) or (nil :: any))

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.EditWebhookMessage, webhookId, webhookToken, messageId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.DeleteWebhookMessageResponse>
end

return Webhook
