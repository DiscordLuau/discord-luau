local stdPolyfills = require("../lune_packages/std_polyfills")

local future = require("../luau_packages/future")
local apiTypes = require("../lune_packages/api_types")

local request = require("./request")

--[=[
	@class Rest.voice

	HTTP Rest API implementation for the following Resource:

	- https://discord.com/developers/docs/resources/voice
]=]
local voice = {}

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/voice#list-voice-regions
]=]
function voice.listVoiceRegionsAsync(
	instance: request.Request
): future.FutureLike<string, apiTypes.ListVoiceRegionsResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(apiTypes.rest.endpoints.ListVoiceRegions)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.ListVoiceRegionsResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/voice#get-current-user-voice-state
]=]
function voice.getCurrentUserVoiceStateAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): future.FutureLike<string, apiTypes.GetCurrentUserVoiceStateResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetCurrentUserVoiceState, guildId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetCurrentUserVoiceStateResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/voice#get-user-voice-state
]=]
function voice.getUserVoiceStateAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	userId: apiTypes.Snowflake
): future.FutureLike<string, apiTypes.GetUserVoiceStateResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetUserVoiceState, guildId, userId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetUserVoiceStateResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/voice#modify-current-user-voice-state
]=]
function voice.modifyCurrentUserVoiceStateAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: apiTypes.ModifyCurrentUserVoiceStateRequest
): future.FutureLike<string, apiTypes.ModifyCurrentUserVoiceStateResponse>
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

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/voice#modify-user-voice-state
]=]
function voice.modifyUserVoiceStateAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	userId: apiTypes.Snowflake,
	jsonParams: apiTypes.ModifyUserVoiceStateRequest
): future.FutureLike<string, apiTypes.ModifyUserVoiceStateResponse>
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

return voice
