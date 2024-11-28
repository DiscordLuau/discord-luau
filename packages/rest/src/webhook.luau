local stdPolyfills = require("../lune_packages/std_polyfills")

local async = require("../lune_packages/async")
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
): async.Async<apiTypes.CreateWebhookResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(apiTypes.rest.endpoints.CreateWebhook, channelId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/webhook#get-channel-webhooks
function Webhook.getChannelWebhooksAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake
): async.Async<apiTypes.GetChannelWebhooksResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetChannelWebhooks, channelId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/webhook#get-guild-webhooks
function Webhook.getGuildWebhooksAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): async.Async<apiTypes.GetGuildWebhooksResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildWebhooks, guildId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/webhook#get-webhook
function Webhook.getWebhookAsync(
	instance: request.Request,
	webhookId: apiTypes.Snowflake
): async.Async<apiTypes.GetWebhookResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetWebhook, webhookId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/webhook#get-webhook-with-token
function Webhook.getWebhookWithTokenAsync(
	instance: request.Request,
	webhookId: apiTypes.Snowflake,
	webhookToken: string
): async.Async<apiTypes.GetWebhookWithTokenResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetWebhookWithToken, webhookId, webhookToken))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/webhook#modify-webhook
function Webhook.modifyWebhookAsync(
	instance: request.Request,
	webhookId: apiTypes.Snowflake,
	jsonParams: apiTypes.ModifyWebhookRequest,
	auditLogReason: string?
): async.Async<apiTypes.GetWebhookWithTokenResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ModifyWebhook, webhookId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/webhook#modify-webhook-with-token
function Webhook.modifyWebhookWithTokenAsync(
	instance: request.Request,
	webhookId: apiTypes.Snowflake,
	webhookToken: string,
	jsonParams: apiTypes.ModifyWebhookRequest,
	auditLogReason: string?
): async.Async<apiTypes.ModifyWebhookRequest>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ModifyWebhookWithToken, webhookId, webhookToken))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/webhook#delete-webhook
function Webhook.deleteWebhookAsync(
	instance: request.Request,
	webhookId: apiTypes.Snowflake,
	auditLogReason: string?
): async.Async<apiTypes.DeleteWebhookResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.DeleteWebhook, webhookId))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/webhook#delete-webhook-with-token
function Webhook.deleteWebhookWithTokenAsync(
	instance: request.Request,
	webhookId: apiTypes.Snowflake,
	webhookToken: string,
	auditLogReason: string?
): async.Async<apiTypes.DeleteWebhookResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.DeleteWebhookWithToken, webhookId, webhookToken))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
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
): async.Async<apiTypes.ExecuteWebhookResponse>
	return async.new(function()
		instance:assertToken()

		instance:addUrlParam("wait", urlParams.wait and tostring(urlParams.wait) or (nil :: any))
		instance:addUrlParam("thread_id", urlParams.threadId and tostring(urlParams.threadId) or (nil :: any))

		instance:setMethod("POST")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ExecuteWebhook, webhookId, webhookToken))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
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
): async.Async<apiTypes.GetWebhookMessageResponse>
	return async.new(function()
		instance:assertToken()

		instance:addUrlParam("thread_id", urlParams.threadId and tostring(urlParams.threadId) or (nil :: any))

		instance:setMethod("POST")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetWebhookMessage, webhookId, webhookToken, messageId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
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
): async.Async<apiTypes.EditWebhookMessageResponse>
	return async.new(function()
		instance:assertToken()

		instance:addUrlParam("thread_id", urlParams.threadId and tostring(urlParams.threadId) or (nil :: any))

		instance:setMethod("PATCH")
		instance:setUrl(string.format(apiTypes.rest.endpoints.EditWebhookMessage, webhookId, webhookToken, messageId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
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
): async.Async<apiTypes.DeleteWebhookMessageResponse>
	return async.new(function()
		instance:assertToken()

		instance:addUrlParam("thread_id", urlParams.threadId and tostring(urlParams.threadId) or (nil :: any))

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.EditWebhookMessage, webhookId, webhookToken, messageId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

return Webhook
