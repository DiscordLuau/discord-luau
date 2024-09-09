local serde = require("@std-polyfills/serde")

local request = require("@rest/request")
local future = require("@vendor/future")

local restTypes = require("@api-types/rest/types")
local apiTypes = require("@api-types/apiTypes")
local restEndpoints = require("@api-types/rest/endpoints")

--[[
	HTTP Rest API implementation for the following Resource:

	- https://discord.com/developers/docs/interactions/application-commands
]]
local Commands = {}

-- https://discord.com/developers/docs/interactions/application-commands#get-global-application-commands
function Commands.getGlobalApplicationCommandsAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	urlParams: {
		withLocalizations: boolean?,
	}
): future.Future<restTypes.GetGlobalApplicationCommandsResponse>
	return future.new(function()
		instance:assertToken()

		instance:addUrlParam("with_localizations", urlParams.withLocalizations and "true" or (nil :: any))

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.GetGlobalApplicationCommands, applicationId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/interactions/application-commands#create-global-application-command
function Commands.createGlobalApplicationCommandAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	jsonParams: restTypes.CreateGlobalApplicationCommandRequest
): future.Future<restTypes.CreateGlobalApplicationCommandResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(restEndpoints.CreateGlobalApplicationCommand, applicationId))
		instance:setBody(serde.encode("json", jsonParams, true))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/interactions/application-commands#get-global-application-command
function Commands.getGlobalApplicationCommandAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	commandId: apiTypes.Snowflake
): future.Future<restTypes.GetGlobalApplicationCommandResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.GetGlobalApplicationCommand, applicationId, commandId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/interactions/application-commands#edit-global-application-command
function Commands.editGlobalApplicationCommandAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	commandId: apiTypes.Snowflake,
	jsonParams: restTypes.EditGlobalApplicationCommandRequest
): future.Future<restTypes.EditGlobalApplicationCommandResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(restEndpoints.EditGlobalApplicationCommand, applicationId, commandId))
		instance:setBody(serde.encode("json", jsonParams, true))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/interactions/application-commands#delete-global-application-command
function Commands.deleteGlobalApplicationCommandAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	commandId: apiTypes.Snowflake
): future.Future<restTypes.DeleteGlobalApplicationCommandResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(restEndpoints.DeleteGlobalApplicationCommand, applicationId, commandId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/interactions/application-commands#bulk-overwrite-global-application-commands
function Commands.bulkOverwriteGlobalApplicationCommandsAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	jsonParams: restTypes.BulkOverwriteGlobalApplicationCommandsRequest
): future.Future<
	restTypes.BulkOverwriteGlobalApplicationCommandsResponse
>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("PUT")
		instance:setUrl(string.format(restEndpoints.BulkOverwriteGlobalApplicationCommands, applicationId))
		instance:setBody(serde.encode("json", jsonParams, true))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/interactions/application-commands#get-guild-application-commands
function Commands.getGuildApplicationCommandsAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	guildId: apiTypes.Snowflake,
	urlParams: {
		withLocalizations: boolean?,
	}
): future.Future<restTypes.GetGuildApplicationCommandsResponse>
	return future.new(function()
		instance:assertToken()

		instance:addUrlParam("with_localizations", urlParams.withLocalizations and "true" or (nil :: any))

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.GetGuildApplicationCommands, applicationId, guildId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/interactions/application-commands#create-guild-application-command
function Commands.createGuildApplicationCommandAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	guildId: apiTypes.Snowflake,
	jsonParams: restTypes.CreateGuildApplicationCommandRequest
): future.Future<restTypes.CreateGuildApplicationCommandResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(restEndpoints.CreateGuildApplicationCommand, applicationId, guildId))
		instance:setBody(serde.encode("json", jsonParams, true))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/interactions/application-commands#get-guild-application-command
function Commands.getGuildApplicationCommandAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	guildId: apiTypes.Snowflake,
	commandId: apiTypes.Snowflake
): future.Future<restTypes.GetGuildApplicationCommandResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.GetGuildApplicationCommand, applicationId, guildId, commandId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/interactions/application-commands#edit-guild-application-command
function Commands.editGuildApplicationCommandAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	guildId: apiTypes.Snowflake,
	commandId: apiTypes.Snowflake,
	jsonParams: restTypes.EditGuildApplicationCommandRequest
): future.Future<restTypes.EditGuildApplicationCommandResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(restEndpoints.EditGuildApplicationCommand, applicationId, guildId, commandId))
		instance:setBody(serde.encode("json", jsonParams, true))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/interactions/application-commands#delete-guild-application-command
function Commands.deleteGuildApplicationCommandAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	guildId: apiTypes.Snowflake,
	commandId: apiTypes.Snowflake
): future.Future<restTypes.DeleteGuildApplicationCommandResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(restEndpoints.DeleteGuildApplicationCommand, applicationId, guildId, commandId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/interactions/application-commands#bulk-overwrite-guild-application-commands
function Commands.bulkOverwriteGuildApplicationCommandsAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	guildId: apiTypes.Snowflake,
	jsonParams: restTypes.BulkOverwriteGuildApplicationCommandsRequest
): future.Future<
	restTypes.BulkOverwriteGuildApplicationCommandsResponse
>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("PUT")
		instance:setUrl(string.format(restEndpoints.BulkOverwriteGuildApplicationCommands, applicationId, guildId))
		instance:setBody(serde.encode("json", jsonParams, true))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/interactions/application-commands#get-guild-application-command-permissions
function Commands.getGuildApplicationCommandPermissionsAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	guildId: apiTypes.Snowflake
): future.Future<
	restTypes.GetGuildApplicationCommandPermissionsResponse
>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.GetGuildApplicationCommandPermissions, applicationId, guildId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/interactions/application-commands#get-application-command-permissions
function Commands.getApplicationCommandPermissionsAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	guildId: apiTypes.Snowflake,
	commandId: apiTypes.Snowflake
): future.Future<
	restTypes.GetApplicationCommandPermissionsResponse
>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(
			string.format(restEndpoints.GetApplicationCommandPermissions, applicationId, guildId, commandId)
		)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/interactions/application-commands#edit-application-command-permissions
function Commands.editApplicationCommandPermissionsAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	guildId: apiTypes.Snowflake,
	commandId: apiTypes.Snowflake,
	jsonParams: restTypes.EditApplicationCommandPermissionsRequest
): future.Future<
	restTypes.EditApplicationCommandPermissionsResponse
>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("PUT")
		instance:setUrl(
			string.format(restEndpoints.EditApplicationCommandPermissions, applicationId, guildId, commandId)
		)
		instance:setBody(serde.encode("json", jsonParams, true))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

return Commands
