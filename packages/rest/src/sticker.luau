local stdPolyfills = require("../lune_packages/std_polyfills")

local async = require("../lune_packages/async")
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
): async.Async<apiTypes.GetStickerResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetSticker, stickerId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/sticker#list-sticker-packs
function Sticker.listStickerPacksAsync(instance: request.Request): async.Async<apiTypes.ListStickerPacksResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(apiTypes.rest.endpoints.ListStickerPacks)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/sticker#list-guild-stickers
function Sticker.listGuildStickersAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): async.Async<apiTypes.ListGuildStickersResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ListGuildStickers, guildId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/sticker#get-guild-sticker
function Sticker.getGuildStickerAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	stickerId: apiTypes.Snowflake
): async.Async<apiTypes.GetGuildStickerResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildSticker, guildId, stickerId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/sticker#create-guild-sticker
function Sticker.createGuildStickerAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: apiTypes.CreateGuildStickerRequest,
	auditLogReason: string?
): async.Async<apiTypes.GetGuildStickerResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(apiTypes.rest.endpoints.CreateGuildSticker, guildId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/sticker#modify-guild-sticker
function Sticker.modifyGuildStickerAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	stickerId: apiTypes.Snowflake,
	jsonParams: apiTypes.ModifyGuildStickerRequest,
	auditLogReason: string?
): async.Async<apiTypes.ModifyGuildStickerResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ModifyGuildSticker, guildId, stickerId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/sticker#delete-guild-sticker
function Sticker.deleteGuildStickerAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	stickerId: apiTypes.Snowflake,
	auditLogReason: string?
): async.Async<apiTypes.DeleteGuildStickerResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.DeleteGuildSticker, guildId, stickerId))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

return Sticker
