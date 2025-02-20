local future = require("../luau_packages/future")
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
)
	return future.Future.new(function()
		instance:assertToken()

		instance:addUrlParam("with_localizations", urlParams.withLocalizations and "true" or (nil :: any))

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGlobalApplicationCommands, applicationId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetGlobalApplicationCommandsResponse>
end

-- https://discord.com/developers/docs/interactions/application-commands#create-global-application-command
function Commands.createGlobalApplicationCommandAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	jsonParams: apiTypes.CreateGlobalApplicationCommandRequest
)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(apiTypes.rest.endpoints.CreateGlobalApplicationCommand, applicationId))
		instance:setBody(apiTypes.rest.endpoints.encode("json", jsonParams, true))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.CreateGlobalApplicationCommandResponse>
end

-- https://discord.com/developers/docs/interactions/application-commands#get-global-application-command
function Commands.getGlobalApplicationCommandAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	commandId: apiTypes.Snowflake
)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGlobalApplicationCommand, applicationId, commandId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetGlobalApplicationCommandResponse>
end

-- https://discord.com/developers/docs/interactions/application-commands#edit-global-application-command
function Commands.editGlobalApplicationCommandAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	commandId: apiTypes.Snowflake,
	jsonParams: apiTypes.EditGlobalApplicationCommandRequest
)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(apiTypes.rest.endpoints.EditGlobalApplicationCommand, applicationId, commandId))
		instance:setBody(apiTypes.rest.endpoints.encode("json", jsonParams, true))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.EditGlobalApplicationCommandResponse>
end

-- https://discord.com/developers/docs/interactions/application-commands#delete-global-application-command
function Commands.deleteGlobalApplicationCommandAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	commandId: apiTypes.Snowflake
)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.DeleteGlobalApplicationCommand, applicationId, commandId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.DeleteGlobalApplicationCommandResponse>
end

-- https://discord.com/developers/docs/interactions/application-commands#bulk-overwrite-global-application-commands
function Commands.bulkOverwriteGlobalApplicationCommandsAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	jsonParams: apiTypes.BulkOverwriteGlobalApplicationCommandsRequest
)
	return future.Future.new(
			function()
				instance:assertToken()

				instance:setMethod("PUT")
				instance:setUrl(
					string.format(apiTypes.rest.endpoints.BulkOverwriteGlobalApplicationCommands, applicationId)
				)
				instance:setBody(apiTypes.rest.endpoints.encode("json", jsonParams, true))

				local response = instance:executeAsync():await()

				assert(response:isOk(), tostring(response:unwrapErr()))

				return response:unwrapOk().body
			end
		) :: future.FutureLike<string, apiTypes.BulkOverwriteGlobalApplicationCommandsResponse>
end

-- https://discord.com/developers/docs/interactions/application-commands#get-guild-application-commands
function Commands.getGuildApplicationCommandsAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	guildId: apiTypes.Snowflake,
	urlParams: {
		withLocalizations: boolean?,
	}
)
	return future.Future.new(function()
		instance:assertToken()

		instance:addUrlParam("with_localizations", urlParams.withLocalizations and "true" or (nil :: any))

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildApplicationCommands, applicationId, guildId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetGuildApplicationCommandsResponse>
end

-- https://discord.com/developers/docs/interactions/application-commands#create-guild-application-command
function Commands.createGuildApplicationCommandAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	guildId: apiTypes.Snowflake,
	jsonParams: apiTypes.CreateGuildApplicationCommandRequest
)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(apiTypes.rest.endpoints.CreateGuildApplicationCommand, applicationId, guildId))
		instance:setBody(apiTypes.rest.endpoints.encode("json", jsonParams, true))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.CreateGuildApplicationCommandResponse>
end

-- https://discord.com/developers/docs/interactions/application-commands#get-guild-application-command
function Commands.getGuildApplicationCommandAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	guildId: apiTypes.Snowflake,
	commandId: apiTypes.Snowflake
)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(
			string.format(apiTypes.rest.endpoints.GetGuildApplicationCommand, applicationId, guildId, commandId)
		)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetGuildApplicationCommandResponse>
end

-- https://discord.com/developers/docs/interactions/application-commands#edit-guild-application-command
function Commands.editGuildApplicationCommandAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	guildId: apiTypes.Snowflake,
	commandId: apiTypes.Snowflake,
	jsonParams: apiTypes.EditGuildApplicationCommandRequest
)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(
			string.format(apiTypes.rest.endpoints.EditGuildApplicationCommand, applicationId, guildId, commandId)
		)
		instance:setBody(apiTypes.rest.endpoints.encode("json", jsonParams, true))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.EditGuildApplicationCommandResponse>
end

-- https://discord.com/developers/docs/interactions/application-commands#delete-guild-application-command
function Commands.deleteGuildApplicationCommandAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	guildId: apiTypes.Snowflake,
	commandId: apiTypes.Snowflake
)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(
			string.format(apiTypes.rest.endpoints.DeleteGuildApplicationCommand, applicationId, guildId, commandId)
		)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.DeleteGuildApplicationCommandResponse_>
end

-- https://discord.com/developers/docs/interactions/application-commands#bulk-overwrite-guild-application-commands
function Commands.bulkOverwriteGuildApplicationCommandsAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	guildId: apiTypes.Snowflake,
	jsonParams: apiTypes.BulkOverwriteGuildApplicationCommandsRequest
)
	return future.Future.new(
			function()
				instance:assertToken()

				instance:setMethod("PUT")
				instance:setUrl(
					string.format(apiTypes.rest.endpoints.BulkOverwriteGuildApplicationCommands, applicationId, guildId)
				)
				instance:setBody(apiTypes.rest.endpoints.encode("json", jsonParams, true))

				local response = instance:executeAsync():await()

				assert(response:isOk(), tostring(response:unwrapErr()))

				return response:unwrapOk().body
			end
		) :: future.FutureLike<string, apiTypes.BulkOverwriteGlobalApplicationCommandsResponse>
end

-- https://discord.com/developers/docs/interactions/application-commands#get-guild-application-command-permissions
function Commands.getGuildApplicationCommandPermissionsAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	guildId: apiTypes.Snowflake
)
	return future.Future.new(
			function()
				instance:assertToken()

				instance:setMethod("GET")
				instance:setUrl(
					string.format(apiTypes.rest.endpoints.GetGuildApplicationCommandPermissions, applicationId, guildId)
				)

				local response = instance:executeAsync():await()

				assert(response:isOk(), tostring(response:unwrapErr()))

				return response:unwrapOk().body
			end
		) :: future.FutureLike<string, apiTypes.GetGuildApplicationCommandPermissionsResponse>
end

-- https://discord.com/developers/docs/interactions/application-commands#get-application-command-permissions
function Commands.getApplicationCommandPermissionsAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	guildId: apiTypes.Snowflake,
	commandId: apiTypes.Snowflake
)
	return future.Future.new(
			function()
				instance:assertToken()

				instance:setMethod("GET")
				instance:setUrl(
					string.format(
						apiTypes.rest.endpoints.GetApplicationCommandPermissions,
						applicationId,
						guildId,
						commandId
					)
				)

				local response = instance:executeAsync():await()

				assert(response:isOk(), tostring(response:unwrapErr()))

				return response:unwrapOk().body
			end
		) :: future.FutureLike<string, apiTypes.GetApplicationCommandPermissionsResponse>
end

-- https://discord.com/developers/docs/interactions/application-commands#edit-application-command-permissions
function Commands.editApplicationCommandPermissionsAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	guildId: apiTypes.Snowflake,
	commandId: apiTypes.Snowflake,
	jsonParams: apiTypes.EditApplicationCommandPermissionsRequest
)
	return future.Future.new(
			function()
				instance:assertToken()

				instance:setMethod("PUT")
				instance:setUrl(
					string.format(
						apiTypes.rest.endpoints.EditApplicationCommandPermissions,
						applicationId,
						guildId,
						commandId
					)
				)
				instance:setBody(apiTypes.rest.endpoints.encode("json", jsonParams, true))

				local response = instance:executeAsync():await()

				assert(response:isOk(), tostring(response:unwrapErr()))

				return response:unwrapOk().body
			end
		) :: future.FutureLike<string, apiTypes.EditApplicationCommandPermissionsResponse>
end

return Commands
