local stdPolyfills = require("../lune_packages/std_polyfills")

local future = require("../luau_packages/future")
local apiTypes = require("../lune_packages/api_types")

local request = require("./request")

--[=[
	@class Rest.guildTemplate

	HTTP Rest API implementation for the following Resource:

	- https://discord.com/developers/docs/resources/guild-template
]=]
local guildTemplate = {}

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/guild-template#get-guild-template
]=]
function guildTemplate.getGuildTemplateAsync(
	instance: request.Request,
	templateCode: string
): future.FutureLike<string, apiTypes.GetGuildTemplateResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildTemplate, templateCode))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetGuildTemplateResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/guild-template#create-guild-from-guild-template
]=]
function guildTemplate.createGuildFromGuildTemplateAsync(
	instance: request.Request,
	templateCode: string,
	jsonParams: apiTypes.CreateGuildFromGuildTemplateRequest
): future.Future<
	string,
	apiTypes.CreateGuildFromGuildTemplateResponse
>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(apiTypes.rest.endpoints.CreateGuildFromTemplate, templateCode))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.CreateGuildFromGuildTemplateResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/guild-template#get-guild-templates
]=]
function guildTemplate.getGuildTemplatesAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): future.FutureLike<string, apiTypes.GetGuildTemplatesResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildTemplates, guildId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetGuildTemplatesResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/guild-template#create-guild-template
]=]
function guildTemplate.createGuildTemplateAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: apiTypes.CreateGuildTemplateRequest
): future.FutureLike<string, apiTypes.CreateGuildTemplateResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(apiTypes.rest.endpoints.CreateGuildTemplate, guildId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.CreateGuildTemplateResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/guild-template#sync-guild-template
]=]
function guildTemplate.syncGuildTemplateAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	templateCode: string
): future.FutureLike<string, apiTypes.SyncGuildTemplateResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("PUT")
		instance:setUrl(string.format(apiTypes.rest.endpoints.SyncGuildTemplate, guildId, templateCode))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.SyncGuildTemplateResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/guild-template#modify-guild-template
]=]
function guildTemplate.modifyGuildTemplateAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	templateCode: string,
	jsonParams: apiTypes.ModifyGuildTemplateRequest
): future.FutureLike<string, apiTypes.ModifyGuildTemplateResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ModifyGuildTemplate, guildId, templateCode))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.ModifyGuildTemplateResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/guild-template#delete-guild-template
]=]
function guildTemplate.deleteGuildTemplateAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	templateCode: string
): future.FutureLike<string, apiTypes.DeleteGuildTemplateResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.DeleteGuildTemplate, guildId, templateCode))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.DeleteGuildTemplateResponse>
end

return guildTemplate
