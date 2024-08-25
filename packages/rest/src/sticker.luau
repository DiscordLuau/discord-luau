local serde = require("@std-polyfills/serde")

local request = require("@rest/request")
local future = require("@vendor/future")

local restTypes = require("@api-types/rest/types")
local apiTypes = require("@api-types/apiTypes")
local restEndpoints = require("@api-types/rest/endpoints")

--[[
	HTTP Rest API implementation for the following Resource:

	- https://discord.com/developers/docs/resources/sticker
]]
local Sticker = {}

-- https://discord.com/developers/docs/resources/sticker#get-sticker
function Sticker.getStickerAsync(
	instance: request.Request,
	stickerId: apiTypes.Snowflake
): future.Future<restTypes.GetStickerResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.GetSticker, stickerId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/sticker#list-sticker-packs
function Sticker.listStickerPacksAsync(instance: request.Request): future.Future<restTypes.ListStickerPacksResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(restEndpoints.ListStickerPacks)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/sticker#list-guild-stickers
function Sticker.listGuildStickersAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): future.Future<restTypes.ListGuildStickersResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.ListGuildStickers, guildId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/sticker#get-guild-sticker
function Sticker.getGuildStickerAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	stickerId: apiTypes.Snowflake
): future.Future<restTypes.GetGuildStickerResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.GetGuildSticker, guildId, stickerId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/sticker#create-guild-sticker
function Sticker.createGuildStickerAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: restTypes.CreateGuildStickerRequest,
	auditLogReason: string?
): future.Future<restTypes.GetGuildStickerResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(restEndpoints.CreateGuildSticker, guildId))
		instance:setBody(serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/sticker#modify-guild-sticker
function Sticker.modifyGuildStickerAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	stickerId: apiTypes.Snowflake,
	jsonParams: restTypes.ModifyGuildStickerRequest,
	auditLogReason: string?
): future.Future<restTypes.ModifyGuildStickerResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(restEndpoints.ModifyGuildSticker, guildId, stickerId))
		instance:setBody(serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/sticker#delete-guild-sticker
function Sticker.deleteGuildStickerAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	stickerId: apiTypes.Snowflake,
	auditLogReason: string?
): future.Future<restTypes.DeleteGuildStickerResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(restEndpoints.DeleteGuildSticker, guildId, stickerId))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

return Sticker
