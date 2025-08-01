local future = require("../luau_packages/future")
local apiTypes = require("../lune_packages/api_types")

local request = require("./request")

--[=[
	@class Rest.commands

	HTTP Rest API implementation for the following Resource:

	- https://discord.com/developers/docs/interactions/application-commands
]=]
local commands = {}

--[=[
	@within Rest.application

	https://discord.com/developers/docs/interactions/application-commands#get-global-application-commands
]=]
function commands.getGlobalApplicationCommandsAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	urlParams: {
		withLocalizations: boolean?,
	}
): future.FutureLike<
	string,
	apiTypes.GetGlobalApplicationCommandsResponse
>
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

--[=[
	@within Rest.application

	https://discord.com/developers/docs/interactions/application-commands#create-global-application-command
]=]
function commands.createGlobalApplicationCommandAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	jsonParams: apiTypes.CreateGlobalApplicationCommandRequest
): future.FutureLike<
	string,
	apiTypes.CreateGlobalApplicationCommandResponse
>
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

--[=[
	@within Rest.application

	https://discord.com/developers/docs/interactions/application-commands#get-global-application-command
]=]
function commands.getGlobalApplicationCommandAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	commandId: apiTypes.Snowflake
): future.FutureLike<
	string,
	apiTypes.GetGlobalApplicationCommandResponse
>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGlobalApplicationCommand, applicationId, commandId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetGlobalApplicationCommandResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/interactions/application-commands#edit-global-application-command
]=]
function commands.editGlobalApplicationCommandAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	commandId: apiTypes.Snowflake,
	jsonParams: apiTypes.EditGlobalApplicationCommandRequest
): future.FutureLike<
	string,
	apiTypes.EditGlobalApplicationCommandResponse
>
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

--[=[
	@within Rest.application

	https://discord.com/developers/docs/interactions/application-commands#delete-global-application-command
]=]
function commands.deleteGlobalApplicationCommandAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	commandId: apiTypes.Snowflake
): future.FutureLike<
	string,
	apiTypes.DeleteGlobalApplicationCommandResponse
>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.DeleteGlobalApplicationCommand, applicationId, commandId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.DeleteGlobalApplicationCommandResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/interactions/application-commands#bulk-overwrite-global-application-commands
]=]
function commands.bulkOverwriteGlobalApplicationCommandsAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	jsonParams: apiTypes.BulkOverwriteGlobalApplicationCommandsRequest
): future.FutureLike<
	string,
	apiTypes.BulkOverwriteGlobalApplicationCommandsResponse
>
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

--[=[
	@within Rest.application

	https://discord.com/developers/docs/interactions/application-commands#get-guild-application-commands
]=]
function commands.getGuildApplicationCommandsAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	guildId: apiTypes.Snowflake,
	urlParams: {
		withLocalizations: boolean?,
	}
): future.FutureLike<
	string,
	apiTypes.GetGuildApplicationCommandsResponse
>
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

--[=[
	@within Rest.application

	https://discord.com/developers/docs/interactions/application-commands#create-guild-application-command
]=]
function commands.createGuildApplicationCommandAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	guildId: apiTypes.Snowflake,
	jsonParams: apiTypes.CreateGuildApplicationCommandRequest
): future.FutureLike<
	string,
	apiTypes.CreateGuildApplicationCommandResponse
>
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

--[=[
	@within Rest.application

	https://discord.com/developers/docs/interactions/application-commands#get-guild-application-command
]=]
function commands.getGuildApplicationCommandAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	guildId: apiTypes.Snowflake,
	commandId: apiTypes.Snowflake
): future.FutureLike<
	string,
	apiTypes.GetGuildApplicationCommandResponse
>
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

--[=[
	@within Rest.application

	https://discord.com/developers/docs/interactions/application-commands#edit-guild-application-command
]=]
function commands.editGuildApplicationCommandAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	guildId: apiTypes.Snowflake,
	commandId: apiTypes.Snowflake,
	jsonParams: apiTypes.EditGuildApplicationCommandRequest
): future.FutureLike<
	string,
	apiTypes.EditGuildApplicationCommandResponse
>
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

--[=[
	@within Rest.application

	https://discord.com/developers/docs/interactions/application-commands#delete-guild-application-command
]=]
function commands.deleteGuildApplicationCommandAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	guildId: apiTypes.Snowflake,
	commandId: apiTypes.Snowflake
): future.FutureLike<
	string,
	apiTypes.DeleteGuildApplicationCommandResponse
>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(
			string.format(apiTypes.rest.endpoints.DeleteGuildApplicationCommand, applicationId, guildId, commandId)
		)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.DeleteGuildApplicationCommandResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/interactions/application-commands#bulk-overwrite-guild-application-commands
]=]
function commands.bulkOverwriteGuildApplicationCommandsAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	guildId: apiTypes.Snowflake,
	jsonParams: apiTypes.BulkOverwriteGuildApplicationCommandsRequest
): future.FutureLike<
	string,
	apiTypes.BulkOverwriteGlobalApplicationCommandsResponse
>
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

--[=[
	@within Rest.application

	https://discord.com/developers/docs/interactions/application-commands#get-guild-application-command-permissions
]=]
function commands.getGuildApplicationCommandPermissionsAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	guildId: apiTypes.Snowflake
): future.FutureLike<
	string,
	apiTypes.GetGuildApplicationCommandPermissionsResponse
>
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

--[=[
	@within Rest.application

	https://discord.com/developers/docs/interactions/application-commands#get-application-command-permissions
]=]
function commands.getApplicationCommandPermissionsAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	guildId: apiTypes.Snowflake,
	commandId: apiTypes.Snowflake
): future.FutureLike<
	string,
	apiTypes.GetApplicationCommandPermissionsResponse
>
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

--[=[
	@within Rest.application

	https://discord.com/developers/docs/interactions/application-commands#edit-application-command-permissions
]=]
function commands.editApplicationCommandPermissionsAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	guildId: apiTypes.Snowflake,
	commandId: apiTypes.Snowflake,
	jsonParams: apiTypes.EditApplicationCommandPermissionsRequest
): future.FutureLike<
	string,
	apiTypes.EditApplicationCommandPermissionsResponse
>
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

return commands
