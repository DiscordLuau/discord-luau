local stdPolyfills = require("../lune_packages/std_polyfills")

local future = require("../luau_packages/future")
local apiTypes = require("../lune_packages/api_types")

local request = require("./request")

--[[
	HTTP Rest API implementation for the following Resource:

	- https://discord.com/developers/docs/resources/voice
]]
local Voice = {}

-- https://discord.com/developers/docs/resources/voice#list-voice-regions
function Voice.listVoiceRegionsAsync(instance: request.Request)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(apiTypes.rest.endpoints.ListVoiceRegions)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.ListVoiceRegionsResponse>
end

-- https://discord.com/developers/docs/resources/voice#get-current-user-voice-state
function Voice.getCurrentUserVoiceStateAsync(instance: request.Request, guildId: apiTypes.Snowflake)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetCurrentUserVoiceState, guildId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetCurrentUserVoiceStateResponse>
end

-- https://discord.com/developers/docs/resources/voice#get-user-voice-state
function Voice.getUserVoiceStateAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	userId: apiTypes.Snowflake
)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetUserVoiceState, guildId, userId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetUserVoiceStateResponse>
end

-- https://discord.com/developers/docs/resources/voice#modify-current-user-voice-state
function Voice.modifyCurrentUserVoiceStateAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: apiTypes.ModifyCurrentUserVoiceStateRequest
)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ModifyCurrentUserVoiceState, guildId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.ModifyCurrentUserVoiceStateResponse>
end

-- https://discord.com/developers/docs/resources/voice#modify-user-voice-state
function Voice.modifyUserVoiceStateAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	userId: apiTypes.Snowflake,
	jsonParams: apiTypes.ModifyUserVoiceStateRequest
)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ModifyUserVoiceState, guildId, userId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.ModifyUserVoiceStateResponse>
end

return Voice
