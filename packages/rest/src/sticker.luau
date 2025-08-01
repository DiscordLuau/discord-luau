local stdPolyfills = require("../lune_packages/std_polyfills")

local future = require("../luau_packages/future")
local apiTypes = require("../lune_packages/api_types")

local request = require("./request")

--[=[
	@class Rest.sticker

	HTTP Rest API implementation for the following Resource:

	- https://discord.com/developers/docs/resources/sticker
]=]
local sticker = {}

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/sticker#get-sticker
]=]
function sticker.getStickerAsync(
	instance: request.Request,
	stickerId: apiTypes.Snowflake
): future.FutureLike<string, apiTypes.GetStickerResponse>
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

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/sticker#list-sticker-packs
]=]
function sticker.listStickerPacksAsync(
	instance: request.Request
): future.FutureLike<string, apiTypes.ListStickerPacksResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(apiTypes.rest.endpoints.ListStickerPacks)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.ListStickerPacksResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/sticker#list-guild-stickers
]=]
function sticker.listGuildStickersAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): future.FutureLike<string, apiTypes.ListGuildStickersResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ListGuildStickers, guildId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.ListGuildStickersResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/sticker#get-guild-sticker
]=]
function sticker.getGuildStickerAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	stickerId: apiTypes.Snowflake
): future.FutureLike<string, apiTypes.GetGuildStickerResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildSticker, guildId, stickerId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetGuildStickerResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/sticker#create-guild-sticker
]=]
function sticker.createGuildStickerAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: apiTypes.CreateGuildStickerRequest,
	auditLogReason: string?
): future.FutureLike<string, apiTypes.CreateGuildStickerResponse>
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

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/sticker#modify-guild-sticker
]=]
function sticker.modifyGuildStickerAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	stickerId: apiTypes.Snowflake,
	jsonParams: apiTypes.ModifyGuildStickerRequest,
	auditLogReason: string?
): future.FutureLike<string, apiTypes.ModifyGuildStickerResponse>
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

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/sticker#delete-guild-sticker
]=]
function sticker.deleteGuildStickerAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	stickerId: apiTypes.Snowflake,
	auditLogReason: string?
): future.FutureLike<string, apiTypes.DeleteGuildStickerResponse>
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

return sticker
