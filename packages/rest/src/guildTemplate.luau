local serde = require("@std-polyfills/serde")

local request = require("@rest/request")
local future = require("@vendor/future")

local restTypes = require("@api-types/rest/types")
local apiTypes = require("@api-types/apiTypes")
local restEndpoints = require("@api-types/rest/endpoints")

--[[
	HTTP Rest API implementation for the following Resource:

	- https://discord.com/developers/docs/resources/guild-template
]]
local GuildTemplate = {}

-- https://discord.com/developers/docs/resources/guild-template#get-guild-template
function GuildTemplate.getGuildTemplateAsync(
	instance: request.Request,
	templateCode: string
): future.Future<restTypes.GetGuildTemplateResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.GetGuildTemplate, templateCode))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild-template#create-guild-from-guild-template
function GuildTemplate.createGuildFromGuildTemplateAsync(
	instance: request.Request,
	templateCode: string,
	jsonParams: restTypes.CreateGuildFromGuildTemplateRequest
): future.Future<restTypes.CreateGuildFromGuildTemplateResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(restEndpoints.CreateGuildFromTemplate, templateCode))
		instance:setBody(serde.encode("json", jsonParams, true))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild-template#get-guild-templates
function GuildTemplate.getGuildTemplatesAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): future.Future<restTypes.GetGuildTemplatesResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.GetGuildTemplates, guildId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild-template#create-guild-template
function GuildTemplate.createGuildTemplateAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: restTypes.CreateGuildTemplateRequest
): future.Future<restTypes.CreateGuildTemplateResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(restEndpoints.CreateGuildTemplate, guildId))
		instance:setBody(serde.encode("json", jsonParams, true))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild-template#sync-guild-template
function GuildTemplate.syncGuildTemplateAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	templateCode: string
): future.Future<restTypes.SyncGuildTemplateResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("PUT")
		instance:setUrl(string.format(restEndpoints.SyncGuildTemplate, guildId, templateCode))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild-template#modify-guild-template
function GuildTemplate.modifyGuildTemplateAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	templateCode: string,
	jsonParams: restTypes.ModifyGuildTemplateRequest
): future.Future<restTypes.ModifyGuildTemplateResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(restEndpoints.ModifyGuildTemplate, guildId, templateCode))
		instance:setBody(serde.encode("json", jsonParams, true))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild-template#delete-guild-template
function GuildTemplate.deleteGuildTemplateAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	templateCode: string
): future.Future<restTypes.ModifyGuildTemplateResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(restEndpoints.DeleteGuildTemplate, guildId, templateCode))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

return GuildTemplate
