local stdPolyfills = require("../lune_packages/std_polyfills")

local future = require("../luau_packages/future")
local apiTypes = require("../lune_packages/api_types")

local request = require("./request")

--[=[
	@class Rest.message

	HTTP Rest API implementation for the following Resource:

	- https://discord.com/developers/docs/resources/message
]=]
local message = {}

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/message#get-channel-messages
]=]
function message.getChannelMessagesAsync(
	instance: request.Request,
	channelId: string,
	urlParams: {
		around: apiTypes.Snowflake?,
		before: apiTypes.Snowflake?,
		after: apiTypes.Snowflake?,
		limit: number?,
	}
): future.FutureLike<string, apiTypes.GetChannelMessagesResponse>
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

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/message#get-channel-message
]=]
function message.getChannelMessageAsync(
	instance: request.Request,
	channelId: string,
	messageId: apiTypes.Snowflake
): future.FutureLike<string, apiTypes.GetChannelMessageResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetChannelMessage, channelId, messageId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetChannelMessageResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/message#create-message
]=]
function message.createMessageAsync(
	instance: request.Request,
	channelId: string,
	jsonParams: apiTypes.CreateMessageRequest
): future.FutureLike<string, apiTypes.CreateMessageResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(apiTypes.rest.endpoints.CreateMessage, channelId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.CreateMessageResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/message#crosspost-message
]=]
function message.crosspostMessageAsync(
	instance: request.Request,
	channelId: string,
	messageId: string
): future.FutureLike<string, apiTypes.CrosspostMessageResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(apiTypes.rest.endpoints.CrosspostMessage, channelId, messageId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.CrosspostMessageResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/message#create-reaction
]=]
function message.createReactionAsync(
	instance: request.Request,
	channelId: string,
	messageId: apiTypes.Snowflake,
	emoji: string
): future.FutureLike<string, apiTypes.CreateReactionResponse>
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

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/message#delete-own-reaction
]=]
function message.deleteOwnReactionAsync(
	instance: request.Request,
	channelId: string,
	messageId: apiTypes.Snowflake,
	emoji: string
): future.FutureLike<string, apiTypes.DeleteOwnReactionResponse>
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

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/message#delete-user-reaction
]=]
function message.deleteUserReactionAsync(
	instance: request.Request,
	channelId: string,
	messageId: apiTypes.Snowflake,
	emoji: string,
	userId: apiTypes.Snowflake
): future.FutureLike<string, apiTypes.DeleteUserReactionResponse>
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

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/message#get-reactions
]=]
function message.getReactionsAsync(
	instance: request.Request,
	channelId: string,
	messageId: apiTypes.Snowflake,
	emoji: string,
	urlParams: {
		type: ("Normal" | "Burst")?,
		after: apiTypes.Snowflake?,
		limit: number?,
	}
): future.FutureLike<string, apiTypes.GetReactionsResponse>
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

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/message#delete-all-reactions
]=]
function message.deleteAllReactionsAsync(
	instance: request.Request,
	channelId: string,
	messageId: apiTypes.Snowflake
): future.FutureLike<string, apiTypes.DeleteAllReactionsResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.DeleteAllReactions, channelId, messageId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.DeleteAllReactionsResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/message#delete-all-reactions-for-emoji
]=]
function message.deleteAllReactionsForEmojiAsync(
	instance: request.Request,
	channelId: string,
	messageId: apiTypes.Snowflake,
	emoji: string
): future.FutureLike<string, apiTypes.DeleteAllReactionsForEmojiResponse>
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

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/message#edit-message
]=]
function message.editMessageAsync(
	instance: request.Request,
	channelId: string,
	messageId: apiTypes.Snowflake,
	jsonParams: apiTypes.EditMessageRequest
): future.FutureLike<string, apiTypes.EditMessageResponse>
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

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/message#delete-message
]=]
function message.deleteMessageAsync(
	instance: request.Request,
	channelId: string,
	messageId: apiTypes.Snowflake,
	auditLogReason: string?
): future.FutureLike<string, apiTypes.DeleteMessageResponse>
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

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/message#bulk-delete-messages
]=]
function message.bulkDeleteMessagesAsync(
	instance: request.Request,
	channelId: string,
	jsonParams: apiTypes.BulkDeleteMessagesRequest,
	auditLogReason: string?
): future.FutureLike<string, apiTypes.BulkDeleteMessageResponse>
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

return message
