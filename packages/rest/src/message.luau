local serde = require("@std-polyfills/serde")
local net = require("@std-polyfills/net")

local request = require("@rest/request")
local future = require("@vendor/future")

local restTypes = require("@api-types/rest/types")
local apiTypes = require("@api-types/apiTypes")
local restEndpoints = require("@api-types/rest/endpoints")

--[[
	HTTP Rest API implementation for the following Resource:

	- https://discord.com/developers/docs/resources/message
]]
local Message = {}

-- https://discord.com/developers/docs/resources/message#get-channel-messages
function Message.getChannelMessagesAsync(
	instance: request.Request,
	channelId: string,
	urlParams: {
		around: apiTypes.Snowflake?,
		before: apiTypes.Snowflake?,
		after: apiTypes.Snowflake?,
		limit: number?,
	}
): future.Future<restTypes.GetChannelMessagesResponse>
	return future.new(function()
		instance:assertToken()

		instance:addUrlParam("around", urlParams.around and tostring(urlParams.around) or (nil :: any))
		instance:addUrlParam("before", urlParams.before and tostring(urlParams.before) or (nil :: any))
		instance:addUrlParam("after", urlParams.after and tostring(urlParams.after) or (nil :: any))
		instance:addUrlParam("limit", urlParams.limit and tostring(urlParams.limit) or (nil :: any))

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.GetChannelMessages, channelId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/message#get-channel-message
function Message.getChannelMessageAsync(
	instance: request.Request,
	channelId: string,
	messageId: apiTypes.Snowflake
): future.Future<restTypes.GetChannelMessageResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.GetChannelMessage, channelId, messageId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/message#create-message
function Message.createMessageAsync(
	instance: request.Request,
	channelId: string,
	jsonParams: restTypes.CreateMessageRequest
): future.Future<restTypes.CreateMessageResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(restEndpoints.CreateMessage, channelId))
		instance:setBody(serde.encode("json", jsonParams, true))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/message#crosspost-message
function Message.crosspostMessageAsync(
	instance: request.Request,
	channelId: string,
	jsonParams: restTypes.CrosspostMessageRequest
): future.Future<restTypes.CrosspostMessageResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(restEndpoints.CrosspostMessage, channelId))
		instance:setBody(serde.encode("json", jsonParams, true))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/message#create-reaction
function Message.createReactionAsync(
	instance: request.Request,
	channelId: string,
	messageId: apiTypes.Snowflake,
	emojiId: apiTypes.Snowflake,
	emojiName: string
): future.Future<restTypes.CreateReactionResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("PUT")
		instance:setUrl(
			string.format(restEndpoints.CreateReaction, channelId, messageId, net.urlEncode(`{emojiName}:{emojiId}`))
		)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/message#delete-own-reaction
function Message.deleteOwnReactionAsync(
	instance: request.Request,
	channelId: string,
	messageId: apiTypes.Snowflake,
	emojiId: apiTypes.Snowflake,
	emojiName: string
): future.Future<restTypes.DeleteOwnReactionResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(
			string.format(restEndpoints.DeleteOwnReaction, channelId, messageId, net.urlEncode(`{emojiName}:{emojiId}`))
		)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/message#delete-user-reaction
function Message.deleteUserReactionAsync(
	instance: request.Request,
	channelId: string,
	messageId: apiTypes.Snowflake,
	emojiId: apiTypes.Snowflake,
	emojiName: string,
	userId: apiTypes.Snowflake
): future.Future<restTypes.DeleteUserReactionResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(
			string.format(
				restEndpoints.DeleteUserReaction,
				channelId,
				messageId,
				net.urlEncode(`{emojiName}:{emojiId}`),
				userId
			)
		)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/message#get-reactions
function Message.getReactionsAsync(
	instance: request.Request,
	channelId: string,
	messageId: apiTypes.Snowflake,
	emojiId: apiTypes.Snowflake,
	emojiName: string,
	urlParams: {
		type: ("Normal" | "Burst")?,
		after: apiTypes.Snowflake?,
		limit: number?,
	}
): future.Future<restTypes.GetReactionsResponse>
	return future.new(function()
		instance:assertToken()

		instance:addUrlParam("type", (urlParams.type and (urlParams.type == "Normal" and 0 or 1)) or (nil :: any))
		instance:addUrlParam("after", urlParams.after and tostring(urlParams.after) or (nil :: any))
		instance:addUrlParam("limit", urlParams.limit and tostring(urlParams.limit) or (nil :: any))

		instance:setMethod("GET")
		instance:setUrl(
			string.format(restEndpoints.GetReactions, channelId, messageId, net.urlEncode(`{emojiName}:{emojiId}`))
		)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/message#delete-all-reactions
function Message.deleteAllReactionsAsync(
	instance: request.Request,
	channelId: string,
	messageId: apiTypes.Snowflake
): future.Future<restTypes.DeleteAllReactionsResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(restEndpoints.DeleteAllReactions, channelId, messageId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/message#delete-all-reactions-for-emoji
function Message.deleteAllReactionsForEmojiAsync(
	instance: request.Request,
	channelId: string,
	messageId: apiTypes.Snowflake,
	emojiId: apiTypes.Snowflake,
	emojiName: string
): future.Future<restTypes.DeleteAllReactionsForEmojiResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(
			string.format(
				restEndpoints.DeleteAllReactions,
				channelId,
				messageId,
				net.urlEncode(`{emojiName}:{emojiId}`)
			)
		)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/message#edit-message
function Message.editMessageAsync(
	instance: request.Request,
	channelId: string,
	messageId: apiTypes.Snowflake,
	jsonParams: restTypes.EditMessageRequest
): future.Future<restTypes.EditMessageResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(restEndpoints.EditMessage, channelId, messageId))
		instance:setBody(serde.encode("json", jsonParams, true))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/message#delete-message
function Message.deleteMessageAsync(
	instance: request.Request,
	channelId: string,
	messageId: apiTypes.Snowflake,
	auditLogReason: string?
): future.Future<restTypes.DeleteMessageResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(restEndpoints.DeleteMessage, channelId, messageId))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/message#bulk-delete-messages
function Message.bulkDeleteMessagesAsync(
	instance: request.Request,
	channelId: string,
	jsonParams: restTypes.BulkDeleteMessagesRequest,
	auditLogReason: string?
): future.Future<restTypes.BulkDeleteMessageResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(restEndpoints.BulkDeleteMessages, channelId))
		instance:setBody(serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

return Message
