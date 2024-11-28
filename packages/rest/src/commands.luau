local async = require("../lune_packages/async")
local apiTypes = require("../lune_packages/api_types")

local request = require("./request")

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
): async.Async<apiTypes.GetGlobalApplicationCommandsResponse>
	return async.new(function()
		instance:assertToken()

		instance:addUrlParam("with_localizations", urlParams.withLocalizations and "true" or (nil :: any))

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGlobalApplicationCommands, applicationId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/interactions/application-commands#create-global-application-command
function Commands.createGlobalApplicationCommandAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	jsonParams: apiTypes.CreateGlobalApplicationCommandRequest
): async.Async<apiTypes.CreateGlobalApplicationCommandResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(apiTypes.rest.endpoints.CreateGlobalApplicationCommand, applicationId))
		instance:setBody(apiTypes.rest.endpoints.encode("json", jsonParams, true))

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
): async.Async<apiTypes.GetGlobalApplicationCommandResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGlobalApplicationCommand, applicationId, commandId))

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
	jsonParams: apiTypes.EditGlobalApplicationCommandRequest
): async.Async<apiTypes.EditGlobalApplicationCommandResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(apiTypes.rest.endpoints.EditGlobalApplicationCommand, applicationId, commandId))
		instance:setBody(apiTypes.rest.endpoints.encode("json", jsonParams, true))

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
): async.Async<apiTypes.DeleteGlobalApplicationCommandResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.DeleteGlobalApplicationCommand, applicationId, commandId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/interactions/application-commands#bulk-overwrite-global-application-commands
function Commands.bulkOverwriteGlobalApplicationCommandsAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	jsonParams: apiTypes.BulkOverwriteGlobalApplicationCommandsRequest
): async.Async<
	apiTypes.BulkOverwriteGlobalApplicationCommandsResponse
>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("PUT")
		instance:setUrl(string.format(apiTypes.rest.endpoints.BulkOverwriteGlobalApplicationCommands, applicationId))
		instance:setBody(apiTypes.rest.endpoints.encode("json", jsonParams, true))

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
): async.Async<apiTypes.GetGuildApplicationCommandsResponse>
	return async.new(function()
		instance:assertToken()

		instance:addUrlParam("with_localizations", urlParams.withLocalizations and "true" or (nil :: any))

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildApplicationCommands, applicationId, guildId))

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
	jsonParams: apiTypes.CreateGuildApplicationCommandRequest
): async.Async<apiTypes.CreateGuildApplicationCommandResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(apiTypes.rest.endpoints.CreateGuildApplicationCommand, applicationId, guildId))
		instance:setBody(apiTypes.rest.endpoints.encode("json", jsonParams, true))

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
): async.Async<apiTypes.GetGuildApplicationCommandResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(
			string.format(apiTypes.rest.endpoints.GetGuildApplicationCommand, applicationId, guildId, commandId)
		)

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
	jsonParams: apiTypes.EditGuildApplicationCommandRequest
): async.Async<apiTypes.EditGuildApplicationCommandResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(
			string.format(apiTypes.rest.endpoints.EditGuildApplicationCommand, applicationId, guildId, commandId)
		)
		instance:setBody(apiTypes.rest.endpoints.encode("json", jsonParams, true))

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
): async.Async<apiTypes.DeleteGuildApplicationCommandResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(
			string.format(apiTypes.rest.endpoints.DeleteGuildApplicationCommand, applicationId, guildId, commandId)
		)

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
	jsonParams: apiTypes.BulkOverwriteGuildApplicationCommandsRequest
): async.Async<
	apiTypes.BulkOverwriteGuildApplicationCommandsResponse
>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("PUT")
		instance:setUrl(
			string.format(apiTypes.rest.endpoints.BulkOverwriteGuildApplicationCommands, applicationId, guildId)
		)
		instance:setBody(apiTypes.rest.endpoints.encode("json", jsonParams, true))

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
): async.Async<
	apiTypes.GetGuildApplicationCommandPermissionsResponse
>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(
			string.format(apiTypes.rest.endpoints.GetGuildApplicationCommandPermissions, applicationId, guildId)
		)

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
): async.Async<apiTypes.GetApplicationCommandPermissionsResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(
			string.format(apiTypes.rest.endpoints.GetApplicationCommandPermissions, applicationId, guildId, commandId)
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
	jsonParams: apiTypes.EditApplicationCommandPermissionsRequest
): async.Async<
	apiTypes.EditApplicationCommandPermissionsResponse
>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("PUT")
		instance:setUrl(
			string.format(apiTypes.rest.endpoints.EditApplicationCommandPermissions, applicationId, guildId, commandId)
		)
		instance:setBody(apiTypes.rest.endpoints.encode("json", jsonParams, true))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

return Commands
