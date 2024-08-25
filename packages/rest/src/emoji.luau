local serde = require("@std-polyfills/serde")

local request = require("@rest/request")
local future = require("@vendor/future")

local restTypes = require("@api-types/rest/types")
local apiTypes = require("@api-types/apiTypes")
local restEndpoints = require("@api-types/rest/endpoints")

--[[
	HTTP Rest API implementation for the following Resource:

	- https://discord.com/developers/docs/resources/emoji#emoji-resource
]]
local Emoji = {}

-- https://discord.com/developers/docs/resources/emoji#list-guild-emojis
function Emoji.listGuildEmojisAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): future.Future<restTypes.ListGuildEmojisResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.ListGuildEmojis, guildId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/emoji#get-guild-emoji
function Emoji.getGuildEmojisAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	emojId: apiTypes.Snowflake
): future.Future<restTypes.GetGuildEmojiResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.GetGuildEmoji, guildId, emojId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/emoji#create-guild-emoji
function Emoji.createGuildEmojiAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: restTypes.CreateGuildEmojiRequest,
	auditLogReason: string?
): future.Future<restTypes.CreateGuildEmojiResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(restEndpoints.GetGuildEmoji, guildId))
		instance:setBody(serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/emoji#modify-guild-emoji
function Emoji.modifyGuildEmojiAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	emojId: apiTypes.Snowflake,
	jsonParams: restTypes.ModifyGuildEmojiRequest,
	auditLogReason: string?
): future.Future<restTypes.ModifyGuildEmojiResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(restEndpoints.ModifyGuildEmoji, guildId, emojId))
		instance:setBody(serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/emoji#delete-guild-emoji
function Emoji.deleteGuildEmojiAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	emojId: apiTypes.Snowflake,
	auditLogReason: string?
): future.Future<restTypes.DeleteGuildEmojiResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(restEndpoints.DeleteGuildEmoji, guildId, emojId))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

return Emoji
