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
)
	return future.Future.new(function()
		instance:assertToken()

		instance:addUrlParam("around", urlParams.around and tostring(urlParams.around) or (nil :: any))
		instance:addUrlParam("before", urlParams.before and tostring(urlParams.before) or (nil :: any))
		instance:addUrlParam("after", urlParams.after and tostring(urlParams.after) or (nil :: any))
		instance:addUrlParam("limit", urlParams.limit and tostring(urlParams.limit) or (nil :: any))

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetChannelMessages, channelId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetChannelMessagesResponse>
end

-- https://discord.com/developers/docs/resources/message#get-channel-message
function Message.getChannelMessageAsync(instance: request.Request, channelId: string, messageId: apiTypes.Snowflake)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetChannelMessage, channelId, messageId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetChannelMessageResponse>
end

-- https://discord.com/developers/docs/resources/message#create-message
function Message.createMessageAsync(
	instance: request.Request,
	channelId: string,
	jsonParams: apiTypes.CreateMessageRequest
)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(apiTypes.rest.endpoints.CreateMessage, channelId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.CreateMessageResponse>
end

-- https://discord.com/developers/docs/resources/message#crosspost-message
function Message.crosspostMessageAsync(
	instance: request.Request,
	channelId: string,
	jsonParams: apiTypes.CrosspostMessageRequest
)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(apiTypes.rest.endpoints.CrosspostMessage, channelId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.CrosspostMessageResponse>
end

-- https://discord.com/developers/docs/resources/message#create-reaction
function Message.createReactionAsync(
	instance: request.Request,
	channelId: string,
	messageId: apiTypes.Snowflake,
	emoji: string
)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("PUT")
		instance:setUrl(
			string.format(
				apiTypes.rest.endpoints.CreateReaction,
				channelId,
				messageId,
				stdPolyfills.net.urlEncode(emoji)
			)
		)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.CreateReactionResponse>
end

-- https://discord.com/developers/docs/resources/message#delete-own-reaction
function Message.deleteOwnReactionAsync(
	instance: request.Request,
	channelId: string,
	messageId: apiTypes.Snowflake,
	emoji: string
)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(
			string.format(
				apiTypes.rest.endpoints.DeleteOwnReaction,
				channelId,
				messageId,
				stdPolyfills.net.urlEncode(emoji)
			)
		)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.DeleteOwnReactionResponse>
end

-- https://discord.com/developers/docs/resources/message#delete-user-reaction
function Message.deleteUserReactionAsync(
	instance: request.Request,
	channelId: string,
	messageId: apiTypes.Snowflake,
	emoji: string,
	userId: apiTypes.Snowflake
)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(
			string.format(
				apiTypes.rest.endpoints.DeleteUserReaction,
				channelId,
				messageId,
				stdPolyfills.net.urlEncode(emoji),
				userId
			)
		)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.DeleteUserReactionResponse>
end

-- https://discord.com/developers/docs/resources/message#get-reactions
function Message.getReactionsAsync(
	instance: request.Request,
	channelId: string,
	messageId: apiTypes.Snowflake,
	emoji: string,
	urlParams: {
		type: ("Normal" | "Burst")?,
		after: apiTypes.Snowflake?,
		limit: number?,
	}
)
	return future.Future.new(function()
		instance:assertToken()

		instance:addUrlParam("type", (urlParams.type and (urlParams.type == "Normal" and 0 or 1)) or (nil :: any))
		instance:addUrlParam("after", urlParams.after and tostring(urlParams.after) or (nil :: any))
		instance:addUrlParam("limit", urlParams.limit and tostring(urlParams.limit) or (nil :: any))

		instance:setMethod("GET")
		instance:setUrl(
			string.format(apiTypes.rest.endpoints.GetReactions, channelId, messageId, stdPolyfills.net.urlEncode(emoji))
		)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetReactionsResponse>
end

-- https://discord.com/developers/docs/resources/message#delete-all-reactions
function Message.deleteAllReactionsAsync(instance: request.Request, channelId: string, messageId: apiTypes.Snowflake)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.DeleteAllReactions, channelId, messageId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.DeleteAllReactionsResponse>
end

-- https://discord.com/developers/docs/resources/message#delete-all-reactions-for-emoji
function Message.deleteAllReactionsForEmojiAsync(
	instance: request.Request,
	channelId: string,
	messageId: apiTypes.Snowflake,
	emoji: string
)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(
			string.format(
				apiTypes.rest.endpoints.DeleteAllReactions,
				channelId,
				messageId,
				stdPolyfills.net.urlEncode(emoji)
			)
		)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.DeleteAllReactionsForEmojiResponse>
end

-- https://discord.com/developers/docs/resources/message#edit-message
function Message.editMessageAsync(
	instance: request.Request,
	channelId: string,
	messageId: apiTypes.Snowflake,
	jsonParams: apiTypes.EditMessageRequest
)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(apiTypes.rest.endpoints.EditMessage, channelId, messageId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.EditMessageResponse>
end

-- https://discord.com/developers/docs/resources/message#delete-message
function Message.deleteMessageAsync(
	instance: request.Request,
	channelId: string,
	messageId: apiTypes.Snowflake,
	auditLogReason: string?
)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.DeleteMessage, channelId, messageId))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.DeleteMessageResponse>
end

-- https://discord.com/developers/docs/resources/message#bulk-delete-messages
function Message.bulkDeleteMessagesAsync(
	instance: request.Request,
	channelId: string,
	jsonParams: apiTypes.BulkDeleteMessagesRequest,
	auditLogReason: string?
)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(apiTypes.rest.endpoints.BulkDeleteMessages, channelId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.BulkDeleteMessageResponse>
end

return Message
