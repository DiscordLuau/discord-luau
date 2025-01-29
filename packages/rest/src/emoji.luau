local stdPolyfills = require("../lune_packages/std_polyfills")

local future = require("../luau_packages/future")
local apiTypes = require("../lune_packages/api_types")

local request = require("./request")

--[[
	HTTP Rest API implementation for the following Resource:

	- https://discord.com/developers/docs/resources/emoji#emoji-resource
]]
local Emoji = {}

-- https://discord.com/developers/docs/resources/emoji#list-guild-emojis
function Emoji.listGuildEmojisAsync(instance: request.Request, guildId: apiTypes.Snowflake)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ListGuildEmojis, guildId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.ListGuildEmojisResponse>
end

-- https://discord.com/developers/docs/resources/emoji#get-guild-emoji
function Emoji.getGuildEmojiAsync(instance: request.Request, guildId: apiTypes.Snowflake, emojId: apiTypes.Snowflake)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildEmoji, guildId, emojId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetGuildEmojiResponse>
end

-- https://discord.com/developers/docs/resources/emoji#create-guild-emoji
function Emoji.createGuildEmojiAsync(
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

-- https://discord.com/developers/docs/resources/emoji#modify-guild-emoji
function Emoji.modifyGuildEmojiAsync(
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

-- https://discord.com/developers/docs/resources/emoji#delete-guild-emoji
function Emoji.deleteGuildEmojiAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	emojId: apiTypes.Snowflake,
	auditLogReason: string?
)
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

return Emoji
