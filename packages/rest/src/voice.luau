local stdPolyfills = require("../lune_packages/std_polyfills")

local async = require("../lune_packages/async")
local apiTypes = require("../lune_packages/api_types")

local request = require("./request")

--[[
	HTTP Rest API implementation for the following Resource:

	- https://discord.com/developers/docs/resources/voice
]]
local Voice = {}

-- https://discord.com/developers/docs/resources/voice#list-voice-regions
function Voice.listVoiceRegionsAsync(instance: request.Request): async.Async<apiTypes.ListVoiceRegionsResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(apiTypes.rest.endpoints.ListVoiceRegions)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/voice#get-current-user-voice-state
function Voice.getCurrentUserVoiceStateAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): async.Async<apiTypes.GetCurrentUserVoiceStateResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetCurrentUserVoiceState, guildId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/voice#get-user-voice-state
function Voice.getUserVoiceStateAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	userId: apiTypes.Snowflake
): async.Async<apiTypes.GetUserVoiceStateResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetUserVoiceState, guildId, userId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/voice#modify-current-user-voice-state
function Voice.modifyCurrentUserVoiceStateAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: apiTypes.ModifyCurrentUserVoiceStateRequest
): async.Async<apiTypes.ModifyCurrentUserVoiceStateResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ModifyCurrentUserVoiceState, guildId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/voice#modify-user-voice-state
function Voice.modifyUserVoiceStateAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	userId: apiTypes.Snowflake,
	jsonParams: apiTypes.ModifyUserVoiceStateRequest
): async.Async<apiTypes.ModifyUserVoiceStateResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ModifyUserVoiceState, guildId, userId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

return Voice
