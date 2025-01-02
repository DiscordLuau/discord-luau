local stdPolyfills = require("../lune_packages/std_polyfills")

local future = require("../luau_packages/future")
local apiTypes = require("../lune_packages/api_types")

local request = require("./request")

--[[
	HTTP Rest API implementation for the following Resource:

	- https://discord.com/developers/docs/resources/sticker
]]
local Sticker = {}

-- https://discord.com/developers/docs/resources/sticker#get-sticker
function Sticker.getStickerAsync(
	instance: request.Request,
	stickerId: apiTypes.Snowflake
): future.Future<string, apiTypes.GetStickerResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetSticker, stickerId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/sticker#list-sticker-packs
function Sticker.listStickerPacksAsync(
	instance: request.Request
): future.Future<string, apiTypes.ListStickerPacksResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(apiTypes.rest.endpoints.ListStickerPacks)

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/sticker#list-guild-stickers
function Sticker.listGuildStickersAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): future.Future<string, apiTypes.ListGuildStickersResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ListGuildStickers, guildId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/sticker#get-guild-sticker
function Sticker.getGuildStickerAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	stickerId: apiTypes.Snowflake
): future.Future<string, apiTypes.GetGuildStickerResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildSticker, guildId, stickerId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/sticker#create-guild-sticker
function Sticker.createGuildStickerAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: apiTypes.CreateGuildStickerRequest,
	auditLogReason: string?
): future.Future<string, apiTypes.GetGuildStickerResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(apiTypes.rest.endpoints.CreateGuildSticker, guildId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/sticker#modify-guild-sticker
function Sticker.modifyGuildStickerAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	stickerId: apiTypes.Snowflake,
	jsonParams: apiTypes.ModifyGuildStickerRequest,
	auditLogReason: string?
): future.Future<string, apiTypes.ModifyGuildStickerResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ModifyGuildSticker, guildId, stickerId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/sticker#delete-guild-sticker
function Sticker.deleteGuildStickerAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	stickerId: apiTypes.Snowflake,
	auditLogReason: string?
): future.Future<string, apiTypes.DeleteGuildStickerResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.DeleteGuildSticker, guildId, stickerId))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

return Sticker
