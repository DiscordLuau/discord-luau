local serde = require("@std-polyfills/serde")

local request = require("@rest/request")
local future = require("@vendor/future")

local restTypes = require("@api-types/rest/types")
local apiTypes = require("@api-types/apiTypes")
local restEndpoints = require("@api-types/rest/endpoints")

--[[
	HTTP Rest API implementation for the following Resource:

	- https://discord.com/developers/docs/resources/voice
]]
local Voice = {}

-- https://discord.com/developers/docs/resources/voice#list-voice-regions
function Voice.listVoiceRegionsAsync(instance: request.Request): future.Future<restTypes.ListVoiceRegionsResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(restEndpoints.ListVoiceRegions)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/voice#get-current-user-voice-state
function Voice.getCurrentUserVoiceStateAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): future.Future<restTypes.GetCurrentUserVoiceStateResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.GetCurrentUserVoiceState, guildId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/voice#get-user-voice-state
function Voice.getUserVoiceStateAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	userId: apiTypes.Snowflake
): future.Future<restTypes.GetUserVoiceStateResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.GetUserVoiceState, guildId, userId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/voice#modify-current-user-voice-state
function Voice.modifyCurrentUserVoiceStateAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: restTypes.ModifyCurrentUserVoiceStateRequest
): future.Future<restTypes.ModifyCurrentUserVoiceStateResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(restEndpoints.ModifyCurrentUserVoiceState, guildId))
		instance:setBody(serde.encode("json", jsonParams, true))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/voice#modify-user-voice-state
function Voice.modifyUserVoiceStateAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	userId: apiTypes.Snowflake,
	jsonParams: restTypes.ModifyUserVoiceStateRequest
): future.Future<restTypes.ModifyUserVoiceStateResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(restEndpoints.ModifyUserVoiceState, guildId, userId))
		instance:setBody(serde.encode("json", jsonParams, true))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

return Voice
