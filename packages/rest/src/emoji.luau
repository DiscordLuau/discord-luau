local stdPolyfills = require("../lune_packages/std_polyfills")

local future = require("../luau_packages/future")
local apiTypes = require("../lune_packages/api_types")

local request = require("./request")

--[=[
	@class Rest.emoji

	HTTP Rest API implementation for the following Resource:

	- https://discord.com/developers/docs/resources/emoji#emoji-resource
]=]
local emoji = {}

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/emoji#list-guild-emojis
]=]
function emoji.listGuildEmojisAsync(instance: request.Request, guildId: apiTypes.Snowflake)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ListGuildEmojis, guildId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.ListGuildEmojisResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/emoji#get-guild-emoji
]=]
function emoji.getGuildEmojiAsync(instance: request.Request, guildId: apiTypes.Snowflake, emojId: apiTypes.Snowflake)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildEmoji, guildId, emojId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetGuildEmojiResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/emoji#create-guild-emoji
]=]
function emoji.createGuildEmojiAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: apiTypes.CreateGuildEmojiRequest,
	auditLogReason: string?
)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(apiTypes.rest.endpoints.CreateGuildEmoji, guildId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.CreateGuildEmojiResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/emoji#modify-guild-emoji
]=]
function emoji.modifyGuildEmojiAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	emojId: apiTypes.Snowflake,
	jsonParams: apiTypes.ModifyGuildEmojiRequest,
	auditLogReason: string?
)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ModifyGuildEmoji, guildId, emojId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.ModifyGuildEmojiResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/emoji#delete-guild-emoji
]=]
function emoji.deleteGuildEmojiAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	emojId: apiTypes.Snowflake,
	auditLogReason: string?
): future.FutureLike<string, apiTypes.DeleteGuildEmojiResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.DeleteGuildEmoji, guildId, emojId))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.DeleteGuildEmojiResponse>
end

return emoji
