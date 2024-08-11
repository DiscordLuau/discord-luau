local serde = require("@std-polyfills/serde")

local request = require("@rest/request")
local future = require("@vendor/future")

local restTypes = require("@api-types/rest/types")
local apiTypes = require("@api-types/apiTypes")
local restEndpoints = require("@api-types/rest/endpoints")

--[[
	HTTP Rest API implementation for the following Resource:

	- https://discord.com/developers/docs/resources/webhook
]]
local Webhook = {}

-- https://discord.com/developers/docs/resources/webhook#create-webhook
function Webhook.createWebhookAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	jsonParams: restTypes.CreateWebhookRequest,
	auditLogReason: string?
): future.Future<restTypes.CreateWebhookResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(restEndpoints.CreateWebhook, channelId))
		instance:setBody(serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/webhook#get-channel-webhooks
function Webhook.getChannelWebhooksAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake
): future.Future<restTypes.GetChannelWebhooksResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.GetChannelWebhooks, channelId))

		local response = instance:executeAsync():await()

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/webhook#get-guild-webhooks
function Webhook.getGuildWebhooksAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): future.Future<restTypes.GetGuildWebhooksResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.GetGuildWebhooks, guildId))

		local response = instance:executeAsync():await()

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/webhook#get-webhook
function Webhook.getWebhookAsync(
	instance: request.Request,
	webhookId: apiTypes.Snowflake
): future.Future<restTypes.GetWebhookResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.GetWebhook, webhookId))

		local response = instance:executeAsync():await()

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/webhook#get-webhook-with-token
function Webhook.getWebhookWithTokenAsync(
	instance: request.Request,
	webhookId: apiTypes.Snowflake,
	webhookToken: string
): future.Future<restTypes.GetWebhookWithTokenResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.GetWebhookWithToken, webhookId, webhookToken))

		local response = instance:executeAsync():await()

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/webhook#modify-webhook
function Webhook.modifyWebhookAsync(
	instance: request.Request,
	webhookId: apiTypes.Snowflake,
	jsonParams: restTypes.ModifyWebhookRequest,
	auditLogReason: string?
): future.Future<restTypes.GetWebhookWithTokenResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(restEndpoints.ModifyWebhook, webhookId))
		instance:setBody(serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/webhook#modify-webhook-with-token
function Webhook.modifyWebhookWithTokenAsync(
	instance: request.Request,
	webhookId: apiTypes.Snowflake,
	webhookToken: string,
	jsonParams: restTypes.ModifyWebhookRequest,
	auditLogReason: string?
): future.Future<restTypes.ModifyWebhookRequest>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(restEndpoints.ModifyWebhookWithToken, webhookId, webhookToken))
		instance:setBody(serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/webhook#delete-webhook
function Webhook.deleteWebhookAsync(
	instance: request.Request,
	webhookId: apiTypes.Snowflake,
	auditLogReason: string?
): future.Future<restTypes.DeleteWebhookResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(restEndpoints.DeleteWebhook, webhookId))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/webhook#delete-webhook-with-token
function Webhook.deleteWebhookWithTokenAsync(
	instance: request.Request,
	webhookId: apiTypes.Snowflake,
	webhookToken: string,
	auditLogReason: string?
): future.Future<restTypes.DeleteWebhookResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(restEndpoints.DeleteWebhookWithToken, webhookId, webhookToken))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/webhook#execute-webhook
function Webhook.executeWebhookAsync(
	instance: request.Request,
	webhookId: apiTypes.Snowflake,
	webhookToken: string,
	jsonParams: restTypes.ExecuteWebhookRequest,
	urlParams: {
		wait: boolean?,
		threadId: apiTypes.Snowflake?,
	}
): future.Future<restTypes.ExecuteWebhookResponse>
	return future.new(function()
		instance:assertToken()

		instance:addUrlParam("wait", urlParams.wait and tostring(urlParams.wait) or (nil :: any))
		instance:addUrlParam("thread_id", urlParams.threadId and tostring(urlParams.threadId) or (nil :: any))

		instance:setMethod("POST")
		instance:setUrl(string.format(restEndpoints.ExecuteWebhook, webhookId, webhookToken))
		instance:setBody(serde.encode("json", jsonParams, true))

		local response = instance:executeAsync():await()

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
): future.Future<restTypes.GetWebhookMessageResponse>
	return future.new(function()
		instance:assertToken()

		instance:addUrlParam("thread_id", urlParams.threadId and tostring(urlParams.threadId) or (nil :: any))

		instance:setMethod("POST")
		instance:setUrl(string.format(restEndpoints.GetWebhookMessage, webhookId, webhookToken, messageId))

		local response = instance:executeAsync():await()

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/webhook#edit-webhook-message
function Webhook.editWebhookMessageAsync(
	instance: request.Request,
	webhookId: apiTypes.Snowflake,
	webhookToken: string,
	messageId: apiTypes.Snowflake,
	jsonParams: restTypes.EditWebhookMessageRequest,
	urlParams: {
		threadId: apiTypes.Snowflake?,
	}
): future.Future<restTypes.EditWebhookMessageResponse>
	return future.new(function()
		instance:assertToken()

		instance:addUrlParam("thread_id", urlParams.threadId and tostring(urlParams.threadId) or (nil :: any))

		instance:setMethod("PATCH")
		instance:setUrl(string.format(restEndpoints.EditWebhookMessage, webhookId, webhookToken, messageId))
		instance:setBody(serde.encode("json", jsonParams, true))

		local response = instance:executeAsync():await()

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
): future.Future<restTypes.DeleteWebhookMessageResponse>
	return future.new(function()
		instance:assertToken()

		instance:addUrlParam("thread_id", urlParams.threadId and tostring(urlParams.threadId) or (nil :: any))

		instance:setMethod("DELETE")
		instance:setUrl(string.format(restEndpoints.EditWebhookMessage, webhookId, webhookToken, messageId))

		local response = instance:executeAsync():await()

		return response.body
	end)
end

return Webhook
