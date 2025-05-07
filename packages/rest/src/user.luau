local stdPolyfills = require("../lune_packages/std_polyfills")

local future = require("../luau_packages/future")
local apiTypes = require("../lune_packages/api_types")

local request = require("./request")

--[=[
	@class Rest.user

	HTTP Rest API implementation for the following Resource:

	- https://discord.com/developers/docs/resources/user
]=]
local user = {}

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/user#get-current-user
]=]
function user.getCurrentUserAsync(instance: request.Request): future.FutureLike<string, apiTypes.GetCurrentUserResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(apiTypes.rest.endpoints.GetCurrentUser)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetCurrentUserResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/user#get-user
]=]
function user.getUserAsync(
	instance: request.Request,
	userId: apiTypes.Snowflake
): future.FutureLike<string, apiTypes.GetUserResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetUser, userId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetUserResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/user#modify-current-user
]=]
function user.modifyCurrentUserAsync(
	instance: request.Request,
	jsonParams: apiTypes.ModifyCurrentUserRequest
): future.FutureLike<string, apiTypes.ModifyCurrentUserResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(apiTypes.rest.endpoints.ModifyCurrentUser)
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.ModifyCurrentUserResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/user#get-current-user-guilds
]=]
function user.getCurrentUserGuildsAsync(
	instance: request.Request,
	urlParams: {
		before: apiTypes.Snowflake?,
		after: apiTypes.Snowflake?,
		limit: number?,
		withCounts: boolean?,
	}
): future.FutureLike<string, apiTypes.GetCurrentUserGuildsResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:addUrlParam("before", urlParams.before and tostring(urlParams.before) or (nil :: any))
		instance:addUrlParam("after", urlParams.after and tostring(urlParams.after) or (nil :: any))
		instance:addUrlParam("limit", urlParams.limit and tostring(urlParams.limit) or (nil :: any))
		instance:addUrlParam("with_counts", urlParams.withCounts and tostring(urlParams.withCounts) or (nil :: any))

		instance:setMethod("GET")
		instance:setUrl(apiTypes.rest.endpoints.GetCurrentUserGuilds)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetCurrentUserGuildsResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/user#get-current-user-guild-member
]=]
function user.getCurrentUserGuildMember(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): future.FutureLike<string, apiTypes.GetCurrentUserGuildMemberResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetCurrentUserGuilds, guildId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetCurrentUserGuildMemberResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/user#leave-guild
]=]
function user.leaveGuildAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): future.FutureLike<string, apiTypes.LeaveGuildResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetCurrentUserGuilds, guildId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.LeaveGuildResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/user#create-dm
]=]
function user.createDMAsync(
	instance: request.Request,
	jsonParams: apiTypes.CreateDMRequest
): future.FutureLike<string, apiTypes.CreateDMResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(apiTypes.rest.endpoints.CreateDM)
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.CreateDMResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/user#create-group-dm
]=]
function user.createGroupDMAsync(
	instance: request.Request,
	jsonParams: apiTypes.CreateGroupDMRequest
): future.FutureLike<string, apiTypes.CreateGroupDMResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(apiTypes.rest.endpoints.CreateGroupDM)
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.CreateGroupDMResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/user#get-current-user-connections
]=]
function user.getCurrentUserConnectionsAsync(
	instance: request.Request
): future.FutureLike<string, apiTypes.GetCurrentUserConnectionResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(apiTypes.rest.endpoints.GetCurrentUserConnections)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetCurrentUserConnectionResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/user#get-current-user-application-role-connection
]=]
function user.getCurrentUserApplicationRoleConnectionAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake
): future.FutureLike<
	string,
	apiTypes.GetCurrentUserApplicationRoleConnectionResponse
>
	return future.Future.new(
			function()
				instance:assertToken()

				instance:setMethod("GET")
				instance:setUrl(
					string.format(apiTypes.rest.endpoints.GetCurrentUserApplicationRolConnections, applicationId)
				)

				local response = instance:executeAsync():await()

				assert(response:isOk(), tostring(response:unwrapErr()))

				return response:unwrapOk().body
			end
		) :: future.FutureLike<string, apiTypes.GetCurrentUserApplicationRoleConnectionResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/user#update-current-user-application-role-connection
]=]
function user.updateCurrentUserApplicationRoleConnectionAsync(
	instance: request.Request,
	applicationId: apiTypes.Snowflake,
	jsonParams: apiTypes.UpdateCurrentUserApplicationRoleConnectionRequest
): future.FutureLike<
	string,
	apiTypes.UpdateCurrentUserApplicationRoleConnectionResponse
>
	return future.Future.new(
			function()
				instance:assertToken()

				instance:setMethod("PUT")
				instance:setUrl(
					string.format(apiTypes.rest.endpoints.UpdateCurrentUserApplicationRoleConnection, applicationId)
				)
				instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))

				local response = instance:executeAsync():await()

				assert(response:isOk(), tostring(response:unwrapErr()))

				return response:unwrapOk().body
			end
		) :: future.FutureLike<string, apiTypes.UpdateCurrentUserApplicationRoleConnectionResponse>
end

return user
