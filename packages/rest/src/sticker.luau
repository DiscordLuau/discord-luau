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
function Sticker.getStickerAsync(instance: request.Request, stickerId: apiTypes.Snowflake)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetSticker, stickerId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		local object: apiTypes.GetStickerResponse = response:unwrapOk().body

		return object
	end) :: future.FutureLike<string, apiTypes.GetStickerResponse>
end

-- https://discord.com/developers/docs/resources/sticker#list-sticker-packs
function Sticker.listStickerPacksAsync(instance: request.Request)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(apiTypes.rest.endpoints.ListStickerPacks)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.ListStickerPacksResponse>
end

-- https://discord.com/developers/docs/resources/sticker#list-guild-stickers
function Sticker.listGuildStickersAsync(instance: request.Request, guildId: apiTypes.Snowflake)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ListGuildStickers, guildId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.ListGuildStickersResponse>
end

-- https://discord.com/developers/docs/resources/sticker#get-guild-sticker
function Sticker.getGuildStickerAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	stickerId: apiTypes.Snowflake
)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildSticker, guildId, stickerId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetGuildStickerResponse>
end

-- https://discord.com/developers/docs/resources/sticker#create-guild-sticker
function Sticker.createGuildStickerAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: apiTypes.CreateGuildStickerRequest,
	auditLogReason: string?
)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(apiTypes.rest.endpoints.CreateGuildSticker, guildId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.CreateGuildStickerResponse>
end

-- https://discord.com/developers/docs/resources/sticker#modify-guild-sticker
function Sticker.modifyGuildStickerAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	stickerId: apiTypes.Snowflake,
	jsonParams: apiTypes.ModifyGuildStickerRequest,
	auditLogReason: string?
)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ModifyGuildSticker, guildId, stickerId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.ModifyGuildStickerResponse>
end

-- https://discord.com/developers/docs/resources/sticker#delete-guild-sticker
function Sticker.deleteGuildStickerAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	stickerId: apiTypes.Snowflake,
	auditLogReason: string?
)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.DeleteGuildSticker, guildId, stickerId))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.DeleteGuildStickerResponse>
end

return Sticker
