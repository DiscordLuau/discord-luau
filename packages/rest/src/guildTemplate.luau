local stdPolyfills = require("../lune_packages/std_polyfills")

local future = require("../luau_packages/future")
local apiTypes = require("../lune_packages/api_types")

local request = require("./request")

--[[
	HTTP Rest API implementation for the following Resource:

	- https://discord.com/developers/docs/resources/guild-template
]]
local GuildTemplate = {}

-- https://discord.com/developers/docs/resources/guild-template#get-guild-template
function GuildTemplate.getGuildTemplateAsync(instance: request.Request, templateCode: string)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildTemplate, templateCode))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetGuildTemplateResponse>
end

-- https://discord.com/developers/docs/resources/guild-template#create-guild-from-guild-template
function GuildTemplate.createGuildFromGuildTemplateAsync(
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

-- https://discord.com/developers/docs/resources/guild-template#get-guild-templates
function GuildTemplate.getGuildTemplatesAsync(instance: request.Request, guildId: apiTypes.Snowflake)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildTemplates, guildId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetGuildTemplatesResponse>
end

-- https://discord.com/developers/docs/resources/guild-template#create-guild-template
function GuildTemplate.createGuildTemplateAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: apiTypes.CreateGuildTemplateRequest
)
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

-- https://discord.com/developers/docs/resources/guild-template#sync-guild-template
function GuildTemplate.syncGuildTemplateAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	templateCode: string
)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("PUT")
		instance:setUrl(string.format(apiTypes.rest.endpoints.SyncGuildTemplate, guildId, templateCode))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.SyncGuildTemplateResponse>
end

-- https://discord.com/developers/docs/resources/guild-template#modify-guild-template
function GuildTemplate.modifyGuildTemplateAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	templateCode: string,
	jsonParams: apiTypes.ModifyGuildTemplateRequest
)
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

-- https://discord.com/developers/docs/resources/guild-template#delete-guild-template
function GuildTemplate.deleteGuildTemplateAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	templateCode: string
)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.DeleteGuildTemplate, guildId, templateCode))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.DeleteGuildTemplateResponse>
end

return GuildTemplate
