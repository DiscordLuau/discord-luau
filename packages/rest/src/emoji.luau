local stdPolyfills = require("../lune_packages/std_polyfills")

local async = require("../lune_packages/async")
local apiTypes = require("../lune_packages/api_types")

local request = require("./request")

--[[
	HTTP Rest API implementation for the following Resource:

	- https://discord.com/developers/docs/resources/emoji#emoji-resource
]]
local Emoji = {}

-- https://discord.com/developers/docs/resources/emoji#list-guild-emojis
function Emoji.listGuildEmojisAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): async.Async<apiTypes.ListGuildEmojisResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ListGuildEmojis, guildId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/emoji#get-guild-emoji
function Emoji.getGuildEmojisAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	emojId: apiTypes.Snowflake
): async.Async<apiTypes.GetGuildEmojiResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildEmoji, guildId, emojId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/emoji#create-guild-emoji
function Emoji.createGuildEmojiAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: apiTypes.CreateGuildEmojiRequest,
	auditLogReason: string?
): async.Async<apiTypes.CreateGuildEmojiResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildEmoji, guildId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/emoji#modify-guild-emoji
function Emoji.modifyGuildEmojiAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	emojId: apiTypes.Snowflake,
	jsonParams: apiTypes.ModifyGuildEmojiRequest,
	auditLogReason: string?
): async.Async<apiTypes.ModifyGuildEmojiResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ModifyGuildEmoji, guildId, emojId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/emoji#delete-guild-emoji
function Emoji.deleteGuildEmojiAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	emojId: apiTypes.Snowflake,
	auditLogReason: string?
): async.Async<apiTypes.DeleteGuildEmojiResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.DeleteGuildEmoji, guildId, emojId))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

return Emoji
