local stdPolyfills = require("../lune_packages/std_polyfills")

local future = require("../luau_packages/future")
local apiTypes = require("../lune_packages/api_types")

local request = require("./request")

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
): future.Future<string, apiTypes.GetChannelMessagesResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:addUrlParam("around", urlParams.around and tostring(urlParams.around) or (nil :: any))
		instance:addUrlParam("before", urlParams.before and tostring(urlParams.before) or (nil :: any))
		instance:addUrlParam("after", urlParams.after and tostring(urlParams.after) or (nil :: any))
		instance:addUrlParam("limit", urlParams.limit and tostring(urlParams.limit) or (nil :: any))

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetChannelMessages, channelId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/message#get-channel-message
function Message.getChannelMessageAsync(
	instance: request.Request,
	channelId: string,
	messageId: apiTypes.Snowflake
): future.Future<string, apiTypes.GetChannelMessageResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetChannelMessage, channelId, messageId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/message#create-message
function Message.createMessageAsync(
	instance: request.Request,
	channelId: string,
	jsonParams: apiTypes.CreateMessageRequest
): future.Future<string, apiTypes.CreateMessageResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(apiTypes.rest.endpoints.CreateMessage, channelId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/message#crosspost-message
function Message.crosspostMessageAsync(
	instance: request.Request,
	channelId: string,
	jsonParams: apiTypes.CrosspostMessageRequest
): future.Future<string, apiTypes.CrosspostMessageResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(apiTypes.rest.endpoints.CrosspostMessage, channelId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/message#create-reaction
function Message.createReactionAsync(
	instance: request.Request,
	channelId: string,
	messageId: apiTypes.Snowflake,
	emojiId: apiTypes.Snowflake,
	emojiName: string
): future.Future<string, apiTypes.CreateReactionResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("PUT")
		instance:setUrl(
			string.format(
				apiTypes.rest.endpoints.CreateReaction,
				channelId,
				messageId,
				stdPolyfills.net.urlEncode(`{emojiName}:{emojiId}`)
			)
		)

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/message#delete-own-reaction
function Message.deleteOwnReactionAsync(
	instance: request.Request,
	channelId: string,
	messageId: apiTypes.Snowflake,
	emojiId: apiTypes.Snowflake,
	emojiName: string
): future.Future<string, apiTypes.DeleteOwnReactionResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(
			string.format(
				apiTypes.rest.endpoints.DeleteOwnReaction,
				channelId,
				messageId,
				stdPolyfills.net.urlEncode(`{emojiName}:{emojiId}`)
			)
		)

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
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
): future.Future<string, apiTypes.DeleteUserReactionResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(
			string.format(
				apiTypes.rest.endpoints.DeleteUserReaction,
				channelId,
				messageId,
				stdPolyfills.net.urlEncode(`{emojiName}:{emojiId}`),
				userId
			)
		)

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
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
): future.Future<string, apiTypes.GetReactionsResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:addUrlParam("type", (urlParams.type and (urlParams.type == "Normal" and 0 or 1)) or (nil :: any))
		instance:addUrlParam("after", urlParams.after and tostring(urlParams.after) or (nil :: any))
		instance:addUrlParam("limit", urlParams.limit and tostring(urlParams.limit) or (nil :: any))

		instance:setMethod("GET")
		instance:setUrl(
			string.format(
				apiTypes.rest.endpoints.GetReactions,
				channelId,
				messageId,
				stdPolyfills.net.urlEncode(`{emojiName}:{emojiId}`)
			)
		)

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/message#delete-all-reactions
function Message.deleteAllReactionsAsync(
	instance: request.Request,
	channelId: string,
	messageId: apiTypes.Snowflake
): future.Future<string, apiTypes.DeleteAllReactionsResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.DeleteAllReactions, channelId, messageId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/message#delete-all-reactions-for-emoji
function Message.deleteAllReactionsForEmojiAsync(
	instance: request.Request,
	channelId: string,
	messageId: apiTypes.Snowflake,
	emojiId: apiTypes.Snowflake,
	emojiName: string
): future.Future<string, apiTypes.DeleteAllReactionsForEmojiResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(
			string.format(
				apiTypes.rest.endpoints.DeleteAllReactions,
				channelId,
				messageId,
				stdPolyfills.net.urlEncode(`{emojiName}:{emojiId}`)
			)
		)

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/message#edit-message
function Message.editMessageAsync(
	instance: request.Request,
	channelId: string,
	messageId: apiTypes.Snowflake,
	jsonParams: apiTypes.EditMessageRequest
): future.Future<string, apiTypes.EditMessageResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(apiTypes.rest.endpoints.EditMessage, channelId, messageId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/message#delete-message
function Message.deleteMessageAsync(
	instance: request.Request,
	channelId: string,
	messageId: apiTypes.Snowflake,
	auditLogReason: string?
): future.Future<string, apiTypes.DeleteMessageResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.DeleteMessage, channelId, messageId))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/message#bulk-delete-messages
function Message.bulkDeleteMessagesAsync(
	instance: request.Request,
	channelId: string,
	jsonParams: apiTypes.BulkDeleteMessagesRequest,
	auditLogReason: string?
): future.Future<string, apiTypes.BulkDeleteMessageResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.BulkDeleteMessages, channelId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

return Message
