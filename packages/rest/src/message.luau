local stdPolyfills = require("../lune_packages/std_polyfills")

local async = require("../lune_packages/async")
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
): async.Async<apiTypes.GetChannelMessagesResponse>
	return async.new(function()
		instance:assertToken()

		instance:addUrlParam("around", urlParams.around and tostring(urlParams.around) or (nil :: any))
		instance:addUrlParam("before", urlParams.before and tostring(urlParams.before) or (nil :: any))
		instance:addUrlParam("after", urlParams.after and tostring(urlParams.after) or (nil :: any))
		instance:addUrlParam("limit", urlParams.limit and tostring(urlParams.limit) or (nil :: any))

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetChannelMessages, channelId))

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
): async.Async<apiTypes.GetChannelMessageResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetChannelMessage, channelId, messageId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/message#create-message
function Message.createMessageAsync(
	instance: request.Request,
	channelId: string,
	jsonParams: apiTypes.CreateMessageRequest
): async.Async<apiTypes.CreateMessageResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(apiTypes.rest.endpoints.CreateMessage, channelId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/message#crosspost-message
function Message.crosspostMessageAsync(
	instance: request.Request,
	channelId: string,
	jsonParams: apiTypes.CrosspostMessageRequest
): async.Async<apiTypes.CrosspostMessageResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(apiTypes.rest.endpoints.CrosspostMessage, channelId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))

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
): async.Async<apiTypes.CreateReactionResponse>
	return async.new(function()
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
): async.Async<apiTypes.DeleteOwnReactionResponse>
	return async.new(function()
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
): async.Async<apiTypes.DeleteUserReactionResponse>
	return async.new(function()
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
): async.Async<apiTypes.GetReactionsResponse>
	return async.new(function()
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
): async.Async<apiTypes.DeleteAllReactionsResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.DeleteAllReactions, channelId, messageId))

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
): async.Async<apiTypes.DeleteAllReactionsForEmojiResponse>
	return async.new(function()
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
	jsonParams: apiTypes.EditMessageRequest
): async.Async<apiTypes.EditMessageResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(apiTypes.rest.endpoints.EditMessage, channelId, messageId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))

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
): async.Async<apiTypes.DeleteMessageResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.DeleteMessage, channelId, messageId))
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
	jsonParams: apiTypes.BulkDeleteMessagesRequest,
	auditLogReason: string?
): async.Async<apiTypes.BulkDeleteMessageResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.BulkDeleteMessages, channelId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

return Message
